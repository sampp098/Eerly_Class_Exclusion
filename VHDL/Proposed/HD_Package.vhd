library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package HD_Package is

    -- Calcul la taille en bit du nombre d'entrée
    function log2c(n : natural) return natural;

    -- Calcul la plus petite puissance de 2 supérieure ou égale au nombre d'entrée
    function next_power_of_two(n : natural) return natural;

end package HD_Package;


package body HD_Package is

    -- Calcul la taille en bit du nombre d'entrée
    function log2c(n : natural) return natural is

        variable res : natural := 0;
        variable val : natural := n;

        begin

            while val > 0 loop
                res := res + 1;
                val := val / 2;
            end loop;

            return res;

        end function;

    -- Calcul la plus petite puissance de 2 supérieure ou égale au nombre d'entrée
    function next_power_of_two(n : natural) return natural is

        variable res : natural := 1;

        begin

            while res < n loop
                res := res * 2;
            end loop;
            
            return res;
        end function;

end package body HD_Package;