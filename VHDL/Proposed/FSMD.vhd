library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity FSMD is
    generic (
        NBR_CLASS           : natural;
        NBR_CLASS_NEXT_POW2 : natural;
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
end entity;

architecture Behavioral of FSMD is

    -- États de la machine d'état
    type state_type is (IDLE, ACCUMULATION, DESACTIVATE);
    signal state_reg  : state_type;
    signal state_next : state_type;

    -- Classes actives du QHV en cours
    signal active_classes_reg       : std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);
    signal active_classes_next      : std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);
    signal predicted_class_idx_reg  : std_logic_vector(log2c(NBR_CLASS - 1) - 1 downto 0);
    signal predicted_class_idx_next : std_logic_vector(log2c(NBR_CLASS - 1) - 1 downto 0);

    -- Indice du segment et tranche en cours de traitement
    signal slice_idx_reg       : unsigned(log2c(NBR_ACC - 1) - 1 downto 0);
    signal slice_idx_next      : unsigned(log2c(NBR_ACC - 1) - 1 downto 0);
    signal segment_idx_reg     : unsigned(log2c(NBR_SEG - 1) - 1 downto 0);
    signal segment_idx_next    : unsigned(log2c(NBR_SEG - 1) - 1 downto 0);
    signal addr_slice_reg      : std_logic_vector(log2c(VECTOR_WIDTH / SLICE_WIDTH - 1) - 1 downto 0);

begin

    -- State and data registers
    process(clk, rstn)
    begin
        if rstn = '0' then
            state_reg                 <= IDLE;
            active_classes_reg        <= (others => '0');
            predicted_class_idx_reg   <= (others => '0');
            slice_idx_reg             <= (others => '0');
            segment_idx_reg           <= (others => '0');
            addr_slice_reg            <= (others => '0');

        elsif rising_edge(clk) then
            state_reg                 <= state_next;
            active_classes_reg        <= active_classes_next;
            predicted_class_idx_reg   <= predicted_class_idx_next;
            slice_idx_reg             <= slice_idx_next;
            segment_idx_reg           <= segment_idx_next;
            addr_slice_reg            <= std_logic_vector(resize((to_unsigned(NBR_ACC, addr_slice_reg'length) * segment_idx_next) + slice_idx_next, addr_slice_reg'length));

        end if;
    end process;

    -- Combinational circuit
    process(state_reg, active_classes_reg, predicted_class_idx_reg, slice_idx_reg, segment_idx_reg, fsmd_start_input, fsmd_findmax_maxIdx_input, active_classes_next)
    begin
        -- Valeurs par défaut
        state_next                <= state_reg;
        fsmd_ready_output         <= '0';
        fsmd_PE_acc_clear_output  <= '0';
        fsmd_PE_acc_enable_output <= '0';
        predicted_class_idx_next  <= predicted_class_idx_reg;
        active_classes_next       <= active_classes_reg ;
        slice_idx_next            <= slice_idx_reg ;
        segment_idx_next          <= segment_idx_reg;

        case state_reg is
            when IDLE =>
                fsmd_ready_output        <= '1';
                fsmd_PE_acc_clear_output <= '1';
                --slice_idx_next           <= (others => '0');
                --segment_idx_next         <= (others => '0');
                --active_classes_next      <= (others => '0');

                if fsmd_start_input = '1' then
                    slice_idx_next      <= (others => '0');
                    segment_idx_next    <= (others => '0');
                    active_classes_next(NBR_CLASS - 1 downto 0) <= (others => '1');
                    state_next          <= ACCUMULATION;

                end if;

            when ACCUMULATION =>
                fsmd_PE_acc_enable_output <= '1';

                if slice_idx_reg = NBR_ACC - 1 then
                    state_next     <= DESACTIVATE;

                else
                    slice_idx_next <= slice_idx_reg + 1;
                
                end if;

            when DESACTIVATE =>
                active_classes_next(to_integer(unsigned(fsmd_findmax_maxIdx_input))) <= '0';

                if segment_idx_reg = NBR_CLASS - 2 then
                    for i in 0 to NBR_CLASS - 1 loop
                        if active_classes_next(i) = '1' then
                            predicted_class_idx_next <= std_logic_vector(to_unsigned(i, predicted_class_idx_next'length));
                        end if;
                    end loop;
                    state_next <= IDLE;

                else
                    slice_idx_next   <= (others => '0');
                    segment_idx_next <= segment_idx_reg + 1;
                    state_next       <= ACCUMULATION;

                end if;

            when OTHERS =>
                state_next <= IDLE;

        end case;
    end process;

    fsmd_MEM_addr_slice_output      <= addr_slice_reg;
    fsmd_active_classes_output      <= active_classes_reg;
    fsmd_predicted_class_idx_output <= predicted_class_idx_reg;

end Behavioral;