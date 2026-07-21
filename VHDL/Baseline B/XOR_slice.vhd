library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity XOR_slice is
    generic(
        SLICE_WIDTH : natural
    );
    port( 
        XOR_slice_input_1  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
        XOR_slice_input_2  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
        
        XOR_slice_output   : out std_logic_vector(SLICE_WIDTH - 1 downto 0)
    );
end XOR_slice;

architecture Behavioral of XOR_slice is

begin

    XOR_vector : for i in 0 to SLICE_WIDTH - 1 generate

        XOR_slice_output(i) <= XOR_slice_input_1(i) xor XOR_slice_input_2(i);
        
    end generate XOR_vector;

end Behavioral;
