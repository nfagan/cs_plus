
function opts = setup(opts)

%   SETUP -- Prepare to run the task based on the saved config file.
%
%     Opens windows, starts EyeTracker, initializes Arduino, etc.
%
%     IN:
%       - `opts` (struct) |OPTIONAL| -- Config file.
%
%     OUT:
%       - `opts` (struct) -- Config file, with additional parameters
%         appended.

if ( nargin < 1 || isempty(opts) )
  opts = cs_plus.config.load();
else
  cs_plus.util.assertions.assert__is_config( opts );
end

STIMULI = opts.STIMULI;
SCREEN = opts.SCREEN;
SERIAL = opts.SERIAL;

%   SCREEN
[windex, wrect] = Screen( 'OpenWindow', SCREEN.index, SCREEN.background_color, SCREEN.rect );

%   WINDOW
WINDOW.center = round( [mean(wrect([1 3])), mean(wrect([2 4]))] );
WINDOW.index = windex;
WINDOW.rect = wrect;

%   TRACKER
edf_dir = opts.PATHS.edf_folder;
edf_number = get_latest_edf_number( edf_dir );
TRACKER = EyeTracker( sprintf('%d.edf', edf_number), edf_dir, WINDOW.index );
TRACKER.bypass = opts.INTERFACE.use_mouse;
TRACKER.init();

%   TIMER
TIMER = Timer();
TIMER.register( opts.TIMINGS.time_in );
TIMER.register( opts.TIMINGS.acquisition );
TIMER.add_timer( 'cs_reward_pulse', Inf );  % will be overridden by reward size

%   IMAGES
IMAGES = struct();

cs_path = fullfile( opts.PATHS.stimuli, 'cs' );
rwd_path = fullfile( opts.PATHS.stimuli, 'reward_size' );
image_exts = { '.png', '.jpg' };

rwd_image_files = {};
cs_image_files = {};

for i = 1:numel(image_exts)
  cs_image_files = union( cs_image_files, shared_utils.io.find(cs_path, image_exts{i}) );
  rwd_image_files = union( rwd_image_files, shared_utils.io.find(rwd_path, image_exts{i}) );
end

IMAGES.cs = cellfun( @(x) struct('file', x, 'image', imread(x)), cs_image_files );
IMAGES.reward_size = cellfun( @(x) struct('file', x, 'image', imread(x)), rwd_image_files );

reward_size_indices = zeros( 1, numel(IMAGES.reward_size) );
for i = 1:numel(IMAGES.reward_size)
  [~, filename] = fileparts( IMAGES.reward_size(i).file );
  digit_ind = isstrprop( filename, 'digit' );
  if ( ~any(digit_ind) )
    error( ['Expected filename "%s" to contain a digit indicating its reward size' ...
      , ', but none was found.'], filename );
  end
  reward_size_indices(i) = str2double( filename(digit_ind) );
end

[~, I] = sort( reward_size_indices );

IMAGES.reward_size = IMAGES.reward_size(I);

%   STIMULI
stim_fs = fieldnames( STIMULI.setup );
for i = 1:numel(stim_fs)
  stim = STIMULI.setup.(stim_fs{i});
  if ( ~isstruct(stim) ), continue; end
  if ( ~isfield(stim, 'class') ), continue; end
  switch ( stim.class )
    case 'Rectangle'
      stim_ = Rectangle( windex, wrect, stim.size );
    case 'Image'
      im = stim.image_matrix;
      stim_ = Image( windex, wrect, stim.size, im );
  end
  stim_.color = stim.color;
  stim_.put( stim.placement );
  if ( stim.has_target )
    duration = stim.target_duration;
    padding = stim.target_padding;
    stim_.make_target( TRACKER, duration );
    stim_.targets{1}.padding = padding;
  end
  STIMULI.(stim_fs{i}) = stim_;
end

if ( numel(IMAGES.cs) > 0 )
  STIMULI.cs.image = IMAGES.cs(1).image;
end
if ( numel(IMAGES.reward_size) > 0 )
  STIMULI.reward_size.image = IMAGES.reward_size(1).image;
  dims = size( IMAGES.reward_size(1).image );
  dims = dims * STIMULI.setup.reward_size.scale(1);
%   displace = STIMULI.setup.reward_size.displacement;
  displace = -STIMULI.setup.cs.size;
  if ( numel(displace) == 2 ), displace = displace(2); end
  STIMULI.reward_size.len = dims(1);
  STIMULI.reward_size.width = dims(2);
  STIMULI.reward_size.vertices = [ 0, 0, dims(1), dims(2) ];
  STIMULI.reward_size.put( STIMULI.setup.reward_size.placement );
  STIMULI.reward_size.shift( 0, displace );
end

%   SERIAL
comm = cs_plus.arduino.get_reward_comm( opts );
comm.bypass = ~opts.INTERFACE.use_reward;
comm.start();
SERIAL.comm = comm;

%   EXPORT
opts.STIMULI = STIMULI;
opts.IMAGES = IMAGES;
opts.WINDOW = WINDOW;
opts.TRACKER = TRACKER;
opts.SERIAL = SERIAL;
opts.TIMER = TIMER;

end

function n = get_latest_edf_number( data_dir )

edfs = shared_utils.io.find( data_dir, '.edf' );
n = numel( edfs ) + 1;

end