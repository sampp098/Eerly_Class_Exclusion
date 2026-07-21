library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity tb_MEM is
end tb_MEM;

architecture Behavioral of tb_MEM is

    component MEM
        generic(
            NBR_ADDRESS  : natural;
            VECTOR_WIDTH : natural;
            SLICE_WIDTH  : natural
        );
        port(
            MEM_addr_HV_input    : in  std_logic_vector(log2c(NBR_ADDRESS - 1) - 1 downto 0);
            MEM_addr_slice_input : in  std_logic_vector(log2c(VECTOR_WIDTH / SLICE_WIDTH) - 1 downto 0);

            MEM_data_output      : out std_logic_vector(SLICE_WIDTH - 1 downto 0)
        );
    end component;

    -- Constantes
    constant NBR_PE       : natural := 4;
    constant NBR_ADDRESS  : natural := 9;
    constant VECTOR_WIDTH : natural := 192;
    constant SLICE_WIDTH  : natural := 16;
    
    -- Types
    type data_array is array(natural range <>) of std_logic_vector(SLICE_WIDTH - 1 downto 0);
    signal base_data : data_array(NBR_PE - 1 downto 0) := (others => (others => '0'));

    -- Signaux internes
    signal slice      : std_logic_vector(log2c(VECTOR_WIDTH / SLICE_WIDTH) - 1 downto 0) := (others => '0');
    signal query_addr : unsigned(log2c(NBR_ADDRESS) - 1 downto 0) := (others => '0');
    signal query_data : std_logic_vector(SLICE_WIDTH - 1 downto 0);

begin

    gen_MEM : for addr in 0 to NBR_PE - 1 generate
        U0 : MEM
            generic map(
                NBR_ADDRESS  => NBR_ADDRESS,
                VECTOR_WIDTH => VECTOR_WIDTH,
                SLICE_WIDTH  => SLICE_WIDTH
            )
            port map(
                MEM_addr_HV_input    => std_logic_vector(to_unsigned(addr, log2c(NBR_ADDRESS - 1))),
                MEM_addr_slice_input => slice,

                MEM_data_output      => base_data(addr)
            );
    end generate;

        U1 : MEM
            generic map(
                NBR_ADDRESS  => NBR_ADDRESS,
                VECTOR_WIDTH => VECTOR_WIDTH,
                SLICE_WIDTH  => SLICE_WIDTH
            )
            port map(
                MEM_addr_HV_input    => std_logic_vector(query_addr),
                MEM_addr_slice_input => slice,

                MEM_data_output      => query_data
            );

    -- Stimulis
    stim_proc : process
    begin
        for i in 19 to 22 loop
            query_addr <= to_unsigned(i, query_addr'length);

            for j in 0 to 2 loop
                slice <= std_logic_vector(to_unsigned(j, slice'length));
                wait for 5 ns;

            end loop;
        end loop;
    end process;
    
end architecture;