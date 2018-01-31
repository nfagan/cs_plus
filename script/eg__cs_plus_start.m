conf = cs_plus.config.load();

data_dir = brains.util.get_latest_data_dir_path();
cs_plus_dir = fullfile( data_dir, 'cs_plus' );

shared_utils.io.require_dir( delay_dir );

conf.PATHS.edf_folder = delay_dir;

conf.SCREEN.rect = [ 1680+1024, 0, 1680+1024*2, 768 ];
% conf.SCREEN.rect = [ 0, 0, 400, 400 ];
conf.SCREEN.index = 0;

conf.STRUCTURE.require_fixation_during_delay = false;

%   CS
conf.STIMULI.setup.cs.target_duration = 0.3;
conf.STIMULI.setup.cs.target_padding = 100;
conf.STIMULI.setup.cs.size = 200;

%   FIXATION SQUARE
conf.STIMULI.setup.fix_square.target_duration = 0.3;
conf.STIMULI.setup.fix_square.target_padding = 100;
conf.STIMULI.setup.fix_square.size = 70;

conf.TIMINGS.time_in.fixation = Inf;
conf.TIMINGS.time_in.cs_presentation = Inf;
conf.TIMINGS.time_in.cs_delay = 0.5;
conf.TIMINGS.time_in.fixation_error = 1;
conf.TIMINGS.time_in.cs_error = 1;
conf.TIMINGS.time_in.iti = 1;

%   `N` seconds to initiate a look to the target. If no look occurs within
%   `N` -> error state. Otherwise, a look must last for the duration
%   defined above in the `target_duration`
conf.TIMINGS.acquisition.aq_cs = 2;
conf.TIMINGS.acquisition.aq_fixation = 6;

conf.INTERFACE.debug = false;
conf.INTERFACE.use_mouse = false;
conf.INTERFACE.use_reward = true;

conf.REWARDS.single_pulse = 0.1;  % s

cs_plus.task.start( conf );