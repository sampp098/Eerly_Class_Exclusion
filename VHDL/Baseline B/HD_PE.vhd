library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity HD_PE is
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
end entity;

-- Architecture HD_PE
architecture Behavioral of HD_PE is

    -- Composant XOR_slice
    component XOR_slice is
        generic(
            SLICE_WIDTH : natural
        );
        port( 
            XOR_slice_input_1  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
            XOR_slice_input_2  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
            
            XOR_slice_output   : out std_logic_vector(SLICE_WIDTH - 1 downto 0)
        );
    end component XOR_slice;

    -- Composant PSUM
    component PSUM is
        generic(
            SLICE_WIDTH : natural -- Doit être une puissance de 2
        );
        port(
            PSUM_slice_input : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
            
            PSUM_sum_output  : out std_logic_vector(log2c(SLICE_WIDTH) - 1 downto 0)
        );
    end component PSUM;

    -- Composant ACC
    component ACC is
        generic(
            VECTOR_WIDTH : natural;
            SLICE_WIDTH  : natural
        );
        port(
            clk                : in  std_logic;
            rstn               : in  std_logic;
            ACC_clear_input    : in  std_logic;
            ACC_enable_input   : in  std_logic;
            ACC_sum_input      : in  std_logic_vector(log2c(SLICE_WIDTH) - 1 downto 0);
    
            ACC_HamDist_output : out std_logic_vector(log2c(VECTOR_WIDTH) - 1 downto 0)
        );
    end component ACC;

    -- Signaux internes
    signal slice_xor  : std_logic_vector(SLICE_WIDTH - 1 downto 0);
    signal sum        : std_logic_vector(log2c(SLICE_WIDTH) - 1 downto 0);

begin

  -- Instanciation XOR_slice
    XOR_slice_0 : component XOR_slice
        generic map(
            SLICE_WIDTH => SLICE_WIDTH
        )
        port map( 
            XOR_slice_input_1  => PE_slice_input_BHV,
            XOR_slice_input_2  => PE_slice_input_QHV,
            
            XOR_slice_output   => slice_xor
        );

    PSUM_0 : component PSUM
        generic map(
            SLICE_WIDTH => SLICE_WIDTH
        )
        port map(
            PSUM_slice_input => slice_xor,
            
            PSUM_sum_output  => sum
        );
    
    ACC_0 : component ACC
        generic map(
            VECTOR_WIDTH => VECTOR_WIDTH,
            SLICE_WIDTH  => SLICE_WIDTH
        )
        port map(
            clk              => clk,
            rstn             => rstn,
            ACC_clear_input  => PE_acc_clear_input,
            ACC_enable_input => PE_acc_enable_input,
            ACC_sum_input    => sum,
    
            ACC_HamDist_output => PE_HamDist_output
        );

end Behavioral;
