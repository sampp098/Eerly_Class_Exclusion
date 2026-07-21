library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

-- NOTES :
-- Ne fonctionne pas pour NBR_PE = 1
-- Ne fonctionne pas pour NBR_SEG = 1
-- Fonctionne pour NBR_ACC = 1
-- Il faut que SLICE_WIDTH soit puissance de 2
-- Il faut que NBR_PE soit puissance de 2
-- Il faut que NBR_PE =< NBR_SEG - 1

entity PU is
    generic (
        NBR_CLASS     : natural; -- Nombre de class
        VECTOR_WIDTH  : natural; -- Taille total des vecteurs
        SLICE_WIDTH   : natural; -- Taille des tranches
        SEGMENT_WIDTH : natural  -- Taille des segments
    );
    port (
        clk  : in std_logic;
        rstn : in std_logic;

        -- État du PU
        PU_start_input  : in  std_logic;
        PU_ready_output : out std_logic;

        -- Prédiction
        PU_predicted_class_idx_output : out std_logic_vector(log2c(NBR_CLASS - 1) - 1 downto 0);

        -- Index du vecteur de requête pour simulation
        simu_PU_query_idx_input : in std_logic_vector(log2c(12 - 1) - 1 downto 0)
    );
end entity;

architecture Behavioral of PU is

    -- Constantes
    constant NBR_CLASS_NEXT_POW2 : natural := next_power_of_two(NBR_CLASS);
    constant NBR_SEG             : natural := VECTOR_WIDTH / SEGMENT_WIDTH;
    constant NBR_ACC             : natural := SEGMENT_WIDTH / SLICE_WIDTH;
    constant ADDR_OFFSET_BHV     : natural := 1;
    constant ADDR_OFFSET_QHV     : natural := 23;
    constant NBR_ADDRESS         : natural := 34;


    -- Composant FSMD
    component FSMD
        generic (
            NBR_CLASS           : natural;
            NBR_CLASS_NEXT_POW2 : natural; -- 1 PE pour 1 classe
            VECTOR_WIDTH        : natural; -- Taille total des vecteurs (NBR_SEG * NBR_ACC * SLICE_WIDTH = data_size)
            SLICE_WIDTH         : natural; -- Taille des tranches
            NBR_SEG             : natural; -- Nombre de segmentation des vecteurs, doit être plus grand que nbr_PE
            NBR_ACC             : natural  -- Nombre d'accumulation dans les PEs
        );
        port (
            clk  : in std_logic;
            rstn : in std_logic;

            -- Contrôle
            fsmd_start_input          : in  std_logic;
            fsmd_ready_output         : out std_logic;
            fsmd_PE_acc_clear_output  : out std_logic;
            fsmd_PE_acc_enable_output : out std_logic;

            -- MEM interfaces
            fsmd_MEM_addr_slice_output : out std_logic_vector(log2c(VECTOR_WIDTH / SLICE_WIDTH - 1) - 1 downto 0);

            -- FindMax interface
            fsmd_findmax_maxIdx_input : in std_logic_vector(log2c(NBR_CLASS_NEXT_POW2 - 1) - 1 downto 0);

            -- Classes actives
            fsmd_active_classes_output : out std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);

            -- Prédiction
            fsmd_predicted_class_idx_output : out std_logic_vector(log2c(NBR_CLASS - 1) - 1 downto 0)
            );
    end component;

   -- Composant HD_PE
    component HD_PE
        generic(
            VECTOR_WIDTH : natural;
            SLICE_WIDTH  : natural -- Doit être une puissance de 2
        );
        port(
            clk                 : in  std_logic;
            rstn                : in  std_logic;
            PE_acc_clear_input  : in  std_logic;
            PE_acc_enable_input : in  std_logic;
            PE_slice_input_BHV  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
            PE_slice_input_QHV  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
    
            PE_HamDist_output   : out std_logic_vector(log2c(VECTOR_WIDTH) - 1 downto 0)
        );
    end component;

    -- Composant Mémoire
    component MEM
        generic(
            NBR_ADDRESS  : natural;
            VECTOR_WIDTH : natural;
            SLICE_WIDTH  : natural
        );
        port(
            MEM_addr_HV_input    : in  std_logic_vector(log2c(NBR_ADDRESS - 1) - 1 downto 0);
            MEM_addr_slice_input : in  std_logic_vector(log2c(VECTOR_WIDTH / SLICE_WIDTH - 1) - 1 downto 0);

            MEM_data_output      : out std_logic_vector(SLICE_WIDTH - 1 downto 0)
        );
    end component;

    -- Composant findMax
    component findMax
        generic (
            NBR_CLASS_NEXT_POW2 : natural;
            VECTOR_WIDTH        : natural
        );
        port (
            findmax_active_input  : in  std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);
            findmax_data_input    : in  std_logic_vector(NBR_CLASS_NEXT_POW2 * log2c(VECTOR_WIDTH) - 1 downto 0);

            findmax_maxIdx_output : out std_logic_vector(log2c(NBR_CLASS_NEXT_POW2 - 1) - 1 downto 0)
        );
    end component;

    -- Types
    type PE_inputs_array is array(natural range <>) of std_logic_vector(SLICE_WIDTH - 1 downto 0);

    -- Signaux de contrôle
    signal MEM_addr_slice : std_logic_vector(log2c(VECTOR_WIDTH / SLICE_WIDTH - 1) - 1 downto 0);
    signal PE_acc_clear   : std_logic;
    signal PE_acc_enable  : std_logic;
    signal findmax_maxIdx : std_logic_vector(log2c(NBR_CLASS_NEXT_POW2 - 1) - 1 downto 0);
    signal active_classes : std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);
    
    -- Signaux de donnée
    signal PE_classes_input : PE_inputs_array(NBR_CLASS - 1 downto 0);
    signal PE_query_input   : std_logic_vector(SLICE_WIDTH - 1 downto 0);
    signal PE_HamDist       : std_logic_vector(NBR_CLASS_NEXT_POW2 * log2c(VECTOR_WIDTH) - 1 downto 0);

    -- Signal pour l'index du vecteur de requête pour simulation
    signal simu_MEM_addr_query : std_logic_vector(log2c(NBR_ADDRESS - 1) - 1 downto 0);
begin

    FSMD_0 : component FSMD
        generic map(
            NBR_CLASS           => NBR_CLASS,
            NBR_CLASS_NEXT_POW2 => NBR_CLASS_NEXT_POW2,
            VECTOR_WIDTH        => VECTOR_WIDTH,
            SLICE_WIDTH         => SLICE_WIDTH,
            NBR_SEG             => NBR_SEG,
            NBR_ACC             => NBR_ACC
        )
        port map(
            clk  => clk,
            rstn => rstn,

            -- Contrôle
            fsmd_start_input          => PU_start_input,
            fsmd_ready_output         => PU_ready_output,
            fsmd_PE_acc_clear_output  => PE_acc_clear,
            fsmd_PE_acc_enable_output => PE_acc_enable,

            -- MEM interfaces
            fsmd_MEM_addr_slice_output => MEM_addr_slice,

            -- FindMax interface
            fsmd_findmax_maxIdx_input => findmax_maxIdx,

            -- Classes actives
            fsmd_active_classes_output => active_classes,

            -- Prediction
            fsmd_predicted_class_idx_output => PU_predicted_class_idx_output
        );


    -- Composants HD_PE
    gen_PE : for i in 0 to NBR_CLASS - 1 generate
        HD_PE_i : HD_PE
            generic map(
                VECTOR_WIDTH => VECTOR_WIDTH,
                SLICE_WIDTH  => SLICE_WIDTH
            )
            port map(
                clk                 => clk,
                rstn                => rstn,
                PE_acc_clear_input  => PE_acc_clear,
                PE_acc_enable_input => PE_acc_enable,
                PE_slice_input_BHV  => PE_classes_input(i),
                PE_slice_input_QHV  => PE_query_input,
        
                PE_HamDist_output => PE_HamDist((i + 1) * log2c(VECTOR_WIDTH) - 1 downto i * log2c(VECTOR_WIDTH))
            );
    end generate;

        -- Composants MEM_classes
    gen_MEM_class : for i in 0 to NBR_CLASS - 1 generate
        MEM_class_i : MEM
            generic map(
                NBR_ADDRESS  => NBR_ADDRESS,
                VECTOR_WIDTH => VECTOR_WIDTH,
                SLICE_WIDTH  => SLICE_WIDTH
            )
            port map(
                MEM_addr_HV_input    => std_logic_vector(to_unsigned(ADDR_OFFSET_BHV + i - 1, log2c(NBR_ADDRESS - 1))),
                MEM_addr_slice_input => MEM_addr_slice,

                MEM_data_output      => PE_classes_input(i)
            );
    end generate;

    -- Composant MEM_query
    MEM_query_i : MEM
        generic map(
            NBR_ADDRESS  => NBR_ADDRESS,
            VECTOR_WIDTH => VECTOR_WIDTH,
            SLICE_WIDTH  => SLICE_WIDTH
        )
        port map(
            MEM_addr_HV_input    => simu_MEM_addr_query,
            MEM_addr_slice_input => MEM_addr_slice,

            MEM_data_output      => PE_query_input
        );
    simu_MEM_addr_query <= std_logic_vector(to_unsigned(ADDR_OFFSET_QHV + to_integer(unsigned(simu_PU_query_idx_input)) - 1, log2c(NBR_ADDRESS - 1)));

    -- Composant findMax
    findMax_0 : component findMax
        generic map(
            NBR_CLASS_NEXT_POW2 => NBR_CLASS_NEXT_POW2,
            VECTOR_WIDTH        => VECTOR_WIDTH
        )
        port map(
            findmax_active_input  => active_classes,
            findmax_data_input    => PE_HamDist,

            findmax_maxIdx_output => findmax_maxIdx
        );
        
    
end architecture Behavioral;

