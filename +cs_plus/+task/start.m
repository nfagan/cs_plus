
function err = start()

%   START -- Attempt to setup and run the task.
%
%     OUT:
%       - `err` (double, MException) -- 0 if successful; otherwise, the
%         raised MException, if setup / run fails.

try
  opts = cs_plus.task.setup();
catch err
  cs_plus.task.cleanup();
  cs_plus.util.print_error_stack( err );
  return;
end

try
  err = 0;
  cs_plus.task.run( opts );
  cs_plus.task.cleanup();
catch err
  cs_plus.task.cleanup();
  cs_plus.util.print_error_stack( err );
end

end