library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity findMin is
    generic (
        NBR_CLASS_NEXT_POW2 : natural;
        VECTOR_WIDTH        : natural
    );
    port (
        findmin_active_input  : in  std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);
        findmin_data_input    : in  std_logic_vector(NBR_CLASS_NEXT_POW2 * log2c(VECTOR_WIDTH) - 1 downto 0);

        findmin_minIdx_output : out std_logic_vector(log2c(NBR_CLASS_NEXT_POW2 - 1) - 1 downto 0)
    );
end entity;

architecture Behavioral of findMin is
    
    -- Types pour stocker les données et index entre les étages
    type data_array_lines   is array (NBR_CLASS_NEXT_POW2 - 1 downto 0) of unsigned(log2c(VECTOR_WIDTH) - 1 downto 0);
    type idx_array_lines    is array (NBR_CLASS_NEXT_POW2 - 1 downto 0) of unsigned(log2c(NBR_CLASS_NEXT_POW2 - 1) - 1 downto 0);
    type active_array_lines is array (NBR_CLASS_NEXT_POW2 - 1 downto 0) of std_logic;

    type data_array_stages   is array (log2c(NBR_CLASS_NEXT_POW2) - 1 downto 0) of data_array_lines;
    type idx_array_stages    is array (log2c(NBR_CLASS_NEXT_POW2) - 1 downto 0) of idx_array_lines;
    type active_array_stages is array (log2c(NBR_CLASS_NEXT_POW2) - 1 downto 0) of active_array_lines;

    -- Signaux internes pour stocker les données et index entre les étages
    signal data_between_stages   : data_array_stages;
    signal idx_between_stages    : idx_array_stages;
    signal active_between_stages : active_array_stages;

begin

    -- Génération des étages de comparaisons successifs
    gen_stages : for s in 0 to log2c(NBR_CLASS_NEXT_POW2) - 1 generate
        gen_stage_s : for i in 0 to (NBR_CLASS_NEXT_POW2 / (2 ** s)) - 1 generate

            -- Premier étage (entrées)
            first_stage : if s = 0 generate

                data_between_stages(s)(i)   <= unsigned(findmin_data_input((i + 1) * log2c(VECTOR_WIDTH) - 1 downto i * log2c(VECTOR_WIDTH)));
                idx_between_stages(s)(i)    <= to_unsigned(i, log2c(NBR_CLASS_NEXT_POW2 - 1));
                active_between_stages(s)(i) <= findmin_active_input(i);

            end generate first_stage;

            -- Entre les étages
            between_stages : if s > 0 generate

                signal sel : std_logic;

                begin

                sel <=
                    '1' when active_between_stages(s - 1)(2 * i + 1) = '1' and active_between_stages(s - 1)(2 * i) = '0' else
                    '0' when active_between_stages(s - 1)(2 * i + 1) = '0' else
                    '1' when data_between_stages(s - 1)(2 * i + 1) < data_between_stages(s - 1)(2 * i) else
                    '0';

                -- Sélection de la data la plus petite, et l'indice correspondant
                data_between_stages(s)(i) <= data_between_stages(s - 1)(2 * i + 1) when sel = '1' else data_between_stages(s - 1)(2 * i);
                idx_between_stages(s)(i)  <= idx_between_stages(s - 1)(2 * i + 1)  when sel = '1' else idx_between_stages(s - 1)(2 * i);
            
                -- L'activation de l'étage suivant est le OR logique des deux d'entrée (car une seule doit survivre)
                active_between_stages(s)(i) <= active_between_stages(s - 1)(2 * i) or active_between_stages(s - 1)(2 * i + 1);

            end generate between_stages;

            -- Dernier étage (sortie)
            last_stage : if s = log2c(NBR_CLASS_NEXT_POW2) - 1 generate

                findmin_minIdx_output <= std_logic_vector(idx_between_stages(s)(0));

            end generate last_stage;

        end generate gen_stage_s;
    end generate gen_stages;

end Behavioral;