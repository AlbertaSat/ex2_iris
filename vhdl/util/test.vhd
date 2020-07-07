package test_util is

    pure function test_report(condition : boolean; msg : string) return boolean;
    procedure test_end(tests_passed : boolean);

end package test_util;

package body test_util is

    pure function test_report(condition : boolean; msg : string) return boolean is
    begin
        if condition then
            report "******************** PASSED: " & msg & " ********************" severity note;
        else
            report "******************** FAILED: " & msg & " ********************" severity error;
        end if;
        return condition;
    end function test_report;

    procedure test_end(tests_passed : boolean) is
    begin
        if tests_passed then
            report "******************** ALL TESTS PASSED ********************" severity note;
        else
            report "******************** TEST(S) FAILED ********************" severity failure;
        end if;
    end procedure test_end;

end package body test_util;