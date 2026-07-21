library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity ACC is
    generic(
        VECTOR_WIDTH : natural;
        SLICE_WIDTH  : natural
    );
    port(
        clk                : in  std_logic;
        rstn               : in  std_logic;
        ACC_clear_input    : in  std_logic;
        ACC_enable_input   : in  std_logic;
        ACC_sum_input      : in  std_logic_vector(log2C(SLICE_WIDTH) - 1 downto 0);
 
        ACC_HamDist_output : out std_logic_vector(log2c(VECTOR_WIDTH) - 1 downto 0)
    );
end entity;

architecture Behavioral of ACC is

    signal acc_reg  : unsigned(log2c(VECTOR_WIDTH) - 1 downto 0);
    signal acc_next : unsigned(log2c(VECTOR_WIDTH) - 1 downto 0);

begin

    reg_proc : process(clk, rstn)
    begin
        if rstn = '0' then
            acc_reg     <= (others => '0');

        elsif rising_edge(clk) then
            acc_reg     <= acc_next;

        end if;
    end process reg_proc;

    combi_proc : process(ACC_clear_input, ACC_enable_input, ACC_sum_input, acc_reg)
    begin
        acc_next <= acc_reg;

        if ACC_clear_input = '1' then
            acc_next <= (others => '0');
        
        elsif ACC_enable_input = '1' then
            acc_next <= acc_reg + resize(unsigned(ACC_sum_input), acc_reg'length);

        end if;
    end process combi_proc;

    ACC_HamDist_output <= std_logic_vector(acc_reg);

end Behavioral;