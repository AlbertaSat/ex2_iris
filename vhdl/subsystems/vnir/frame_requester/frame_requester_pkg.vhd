library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package frame_requester_pkg is

    type config_t is record
        num_frames : integer;
        fps : integer;
        exposure_time : integer;
    end record config_t;

    -- type status_t is record

    -- end record status_t;

end package frame_requester_pkg;
