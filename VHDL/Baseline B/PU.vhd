library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

-- PU BASELINE

entity PU is
    generic (
        NBR_CLASS_NEXT_POW2 : natural;
        NBR_CLASS           : natural; -- Nombre de class
        VECTOR_WIDTH        : natural; -- Taille total des vecteurs
        SLICE_WIDTH         : natural -- Taille des tranches
    );
    port (
        clk  : in std_logic;
        rstn : in std_logic;

        -- État du PU
        PU_start_input  : in  std_logic;

        -- Prédiction
        PU_predicted_class_idx_output : out std_logic_vector(log2c(NBR_CLASS - 1) - 1 downto 0);

        -- Index du vecteur de requête pour simulation
        MEM_addr_slice          : in std_logic_vector(log2c(VECTOR_WIDTH / SLICE_WIDTH - 1) - 1 downto 0);
        simu_PU_query_idx_input : in std_logic_vector(log2c(12 - 1) - 1 downto 0)
    );
end entity;

architecture Behavioral of PU is

    -- Constantes
    constant ADDR_OFFSET_BHV     : natural := 1;
    constant ADDR_OFFSET_QHV     : natural := 23;
    constant NBR_ADDRESS         : natural := 34;

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

    -- Composant findMin
    component findMin
        generic (
            NBR_CLASS_NEXT_POW2 : natural;
            VECTOR_WIDTH        : natural
        );
        port (
            findmin_active_input  : in  std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);
            findmin_data_input    : in  std_logic_vector(NBR_CLASS_NEXT_POW2 * log2c(VECTOR_WIDTH) - 1 downto 0);

            findmin_minIdx_output : out std_logic_vector(log2c(NBR_CLASS_NEXT_POW2 - 1) - 1 downto 0)
        );
    end component;

    -- Types
    type PE_inputs_array is array(natural range <>) of std_logic_vector(SLICE_WIDTH - 1 downto 0);

    -- Signaux de contrôle
    signal active_classes : std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);
    
    -- Signaux de donnée
    signal PE_classes_input : PE_inputs_array(NBR_CLASS - 1 downto 0);
    signal PE_query_input   : std_logic_vector(SLICE_WIDTH - 1 downto 0);
    signal PE_HamDist       : std_logic_vector(NBR_CLASS_NEXT_POW2 * log2c(VECTOR_WIDTH) - 1 downto 0);

    -- Signal pour l'index du vecteur de requête pour simulation
    signal simu_MEM_addr_query : std_logic_vector(log2c(NBR_ADDRESS - 1) - 1 downto 0);
begin

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
                PE_acc_clear_input  => PU_start_input,
                PE_acc_enable_input => '1',
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

    -- Composant findMin
    findMin_0 : component findMin
        generic map(
            NBR_CLASS_NEXT_POW2 => NBR_CLASS_NEXT_POW2,
            VECTOR_WIDTH        => VECTOR_WIDTH
        )
        port map(
            findmin_active_input  => active_classes,
            findmin_data_input    => PE_HamDist,

            findmin_minIdx_output => PU_predicted_class_idx_output
        );
    active_classes(NBR_CLASS_NEXT_POW2 - 1 downto NBR_CLASS) <= (others => '0');
    active_classes(NBR_CLASS - 1 downto 0)                   <= (others => '1');  
        
    
end architecture Behavioral;

