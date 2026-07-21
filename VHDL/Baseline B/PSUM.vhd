library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity PSUM is
    generic(
        SLICE_WIDTH : natural
    );
    port(
        PSUM_slice_input : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
        
        PSUM_sum_output  : out std_logic_vector(log2c(SLICE_WIDTH) - 1 downto 0)
    );
end entity;

architecture Behavioral of PSUM is

    -- Types pour stocker les données entre les étages
    type data_array_lines  is array(SLICE_WIDTH - 1 downto 0) of unsigned(log2c(SLICE_WIDTH) - 1 downto 0);
    type data_array_stages is array(log2c(SLICE_WIDTH) - 1 downto 0) of data_array_lines;

    -- Signaux internes pour stocker les données entre les étages
    signal data_between_stages : data_array_stages;

begin
    
    -- Génération des étages de comparaisons successifs
    gen_stages : for s in 0 to log2c(SLICE_WIDTH) - 1 generate
        gen_stage_s : for i in 0 to (SLICE_WIDTH / (2 ** s)) - 1 generate

            -- Premier étage (entrées)
            first_stage : if s = 0 generate

                data_between_stages(s)(i)(log2c(SLICE_WIDTH) - 1 downto 1) <= (others => '0');
                data_between_stages(s)(i)(0) <= PSUM_slice_input(i);

            end generate first_stage;

            -- Entre les étages
            between_stages : if s > 0 generate

                data_between_stages(s)(i) <= data_between_stages(s - 1)(2 * i) + data_between_stages(s - 1)(2 * i + 1);
                
            end generate between_stages;

            -- Dernier étage (sortie)
            last_stage : if s = log2c(SLICE_WIDTH) - 1 generate

                PSUM_sum_output <= std_logic_vector(data_between_stages(s)(0));

            end generate last_stage;

        end generate gen_stage_s;
    end generate gen_stages;

end architecture;