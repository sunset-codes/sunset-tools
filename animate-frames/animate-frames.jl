"""
NOTE THAT TO CREATE ANIMATIONS IN PARAVIEW, YOU CAN JUST
USE 'SAVE ANIMATION' AND THE CHOOSE THE `.AVI` FILE TYPE

This script, however, allows for the creation of arbitrary
generation of movies from any group of images via the
VideoIO.jl Julia package

Arguments:
1       path to images directory. Defaults to `.../animate-frames/frames/`
2       fps. Defaults to 1
3       (optional) output video file name. Defaults to "video_<DATE+TIME>.mp4"
"""

using VideoIO, Dates, ProgressMeter


arg_images_dir = joinpath(@__DIR__, "frames")
arg_fps = 24
arg_video_path = string("video_", Dates.now(), ".mp4")
if length(ARGS) < 2
    printstyled("Error: Not enough arguments")
elseif length(ARGS) == 2
    arg_images_dir = ARGS[1]
    arg_fps = tryparse(Int64, ARGS[2])
else
    arg_images_dir = ARGS[1]
    arg_fps = tryparse(Int64, ARGS[2])
    arg_video_path = ARGS[3]
end

# For static we would use a frame_stack of
# image_stack = map(x->rand(UInt8, 100, 100), 1:100) #vector of 2D arrays

frame_paths = joinpath.(arg_images_dir, readdir(arg_images_dir))
load_frame(frame_path) = VideoIO.load(frame_path)[1]

function process_frame(frame)
    # Ensure each element of frame_stack is a matrix with even x and y lengths 
    x_dim = size(frame, 1)
    y_dim = size(frame, 2)
    frame_mat = transpose(frame[1:(2 * (x_dim ÷ 2)), 1:(2 * (y_dim ÷ 2))])
    # This took too long
    return PermutedDimsArray{eltype(frame_mat), 2, (2, 1), (2, 1), typeof(frame_mat)}(frame_mat)

end

encoder_options = (crf = 23, preset = "medium")
# encoder_options = (crf = 0, preset = "ultrafast")

first_frame = load_frame(frame_paths[1])

open_video_out(
    arg_video_path, first_frame;
    framerate = arg_fps, encoder_options = encoder_options
) do video_writer
    @showprogress "Encoding video frames" for frame_path in frame_paths
        frame = load_frame(frame_path) |> process_frame
        write(video_writer, frame)
    end
end

println()
println("video generated")
println()
