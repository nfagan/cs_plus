
function conf = create(do_save)

%   CREATE -- Create the config file. 
%
%     Define editable properties of the config file here.
%
%     IN:
%       - `do_save` (logical) -- Indicate whether to save the created
%         config file. Default is `false`

if ( nargin < 1 ), do_save = false; end

KbName( 'UnifyKeyNames' );

const = cs_plus.config.constants();

conf = struct();

%   ID
conf.(const.config_id) = true;

%   PATHS
PATHS = struct();
PATHS.repositories = '';
PATHS.stimuli = fullfile( cs_plus.util.get_project_folder(), 'stimuli' );
PATHS.edf_folder = cd;

%   DEPENDENCIES
DEPENDS = struct();
DEPENDS.repositories = { 'ptb_helpers', 'serial_comm' };

%   INTERFACE
INTERFACE = struct();
INTERFACE.stop_key = KbName( 'escape' );
INTERFACE.use_mouse = true;
INTERFACE.use_reward = true;
INTERFACE.is_master_arduino = false;
INTERFACE.debug = true;

%   STRUCTURE
STRUCTURE = struct();
STRUCTURE.require_fixation_during_delay = false;

%   SCREEN
SCREEN = struct();

SCREEN.full_size = get( 0, 'screensize' );
SCREEN.index = 0;
SCREEN.background_color = [ 0 0 0 ];
SCREEN.rect = [ 0, 0, 1024, 768 ];

%   TIMINGS
TIMINGS = struct();

time_in = struct();
time_in.fixation = 2;
time_in.cs_presentation = Inf;
time_in.cs_delay = 1;
time_in.cs_reward = 1;
time_in.iti = 1;
time_in.fixation_error = 0.5;
time_in.cs_error = 0.5;

acquisition = struct();
acquisition.aq_fixation = 1;
acquisition.aq_cs = 1;

TIMINGS.time_in = time_in;
TIMINGS.acquisition = acquisition;

%   TRACKER
TRACKER = [];

%   REWARDS
REWARDS = struct();
REWARDS.single_pulse = 0.3;

%   STIMULI
STIMULI = struct();
STIMULI.setup = struct();

non_editable_properties = {{ 'placement', 'has_target', 'image_matrix' }};

STIMULI.setup.fix_square = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  0.5 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.cs = struct( ...
    'class',            'Image' ...
  , 'size',             [ 100 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  0.5 ...
  , 'target_padding',   0 ...
  , 'image_matrix',     [] ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.reward_size = struct( ...
    'class',            'Image' ...
  , 'size',             [ 50, 50 ] ...
  , 'scale',            1 ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'displacement',     [ 0, -100 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'image_matrix',     [] ...
  , 'non_editable',     non_editable_properties ...
);

%	SERIAL
SERIAL = struct();
SERIAL.ports.reward = 'COM3';
SERIAL.outputs.reward = [ 1, 2 ];
SERIAL.channels = { 'A', 'B' };

%   EXPORT
conf.PATHS = PATHS;
conf.DEPENDS = DEPENDS;
conf.TIMINGS = TIMINGS;
conf.STIMULI = STIMULI;
conf.SCREEN = SCREEN;
conf.INTERFACE = INTERFACE;
conf.SERIAL = SERIAL;
conf.TRACKER = TRACKER;
conf.REWARDS = REWARDS;

if ( do_save )
  cs_plus.config.save( conf );
end

end