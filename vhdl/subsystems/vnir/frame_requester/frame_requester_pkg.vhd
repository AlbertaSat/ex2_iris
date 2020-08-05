library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vnir_types.all;

package frame_requester_pkg is

    type frame_requester_config_t is record
        num_frames : integer;
        fps : integer;
        exposure_time : integer;
    end record frame_requester_config_t;

end package frame_requester_pkg;
