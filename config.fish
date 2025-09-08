if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
end

# Adjusts color theme
set fish_color_error \#c56a72

# Runs Neofetch on start
# neofetch

# Adds Fish to $PATH
set PATH $PATH /path/to/fish

# removes greeting message
set fish_greeting ''

# Removes timestamps
function fish_right_prompt
    #intentionally left blank
end

# Function definitions

function code
    /mnt/c/Users/leyto/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code $argv
end

function c --wraps code --description "VS Code shortcut"
    code $argv
end

function ls --wraps ls --description "List contents of directory"
    exa -F $argv
end

function la --wraps ls --description "List contents of directory, including hidden files"
    exa -Fa $argv
end

function l --wraps ls --description "List contents of directory, using long format"
    exa -lh --no-user --no-time $argv
end

function ll --wraps ls --description "List contents of directory, including hidden files using long format"
    exa -lah --no-user --no-time $argv
end

function g --wraps git
    git $argv
end

function neo
    neofetch
end

function cl
    clear
end

function here --wraps pwd
    set output (pwd)
    set output (string replace -a ' ' '\ ' $output)
    set output (string replace -a '(' '\(' $output)
    set output (string replace -a ')' '\)' $output)
    echo "cd" $output
end

# compiles and runs a c program
function crun
    # Check if at least one argument (the source file) is provided
    if test -z "$argv[1]"
        if set -q last_crun_program
            set source_file $last_crun_program
        else
            echo (set_color red)Usage: crun <source_file.c> [args...] or crun to rerun the last program(set_color normal)
            return 1
        end
    else
        set source_file $argv[1]
        # Save the last run program using a universal variable
        set -U last_crun_program $source_file
    end

    set executable (basename $source_file '.c')

    # Compile the C program using gcc
    gcc -o $executable $source_file

    # Check if compilation was successful
    if test $status -eq 0
        echo (set_color -u '#92d8ff')Compilation successful. Running $executable...(set_color normal)

        # Record start time in nanoseconds
        set start_time (date +%s%N)

        # Run the compiled program with the additional arguments
        ./$executable $argv[2..-1]

        # Record end time in nanoseconds
        set end_time (date +%s%N)

        # Calculate runtime
        set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

        if test $runtime_milliseconds -ge 1000
            set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
        else
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
        end

        # Clean up: remove the executable file
        rm $executable

    else
        echo (set_color red)Compilation failed.(set_color normal)
    end
end

# compiles and runs a C# program
function csrun
    # Check if at least one argument (the source file) is provided
    if test -z "$argv[1]"
        if set -q last_csrun_program
            set source_file $last_csrun_program
        else
            echo (set_color red)Usage: csrun <source_file.cs> [args...] or csrun to rerun the last program(set_color normal)
            return 1
        end
    else
        set source_file $argv[1]
        # Save the last run program using a universal variable
        set -U last_csrun_program $source_file
    end

    set executable (basename $source_file '.cs').exe

    # Compile the C# program using mcs
    mcs -out:$executable $source_file

    # Check if compilation was successful
    if test $status -eq 0
        echo (set_color -u '#92d8ff')Compilation successful. Running $executable...(set_color normal)

        # Record start time in nanoseconds
        set start_time (date +%s%N)

        # Run the compiled program with the additional arguments
        mono $executable $argv[2..-1]

        # Record end time in nanoseconds
        set end_time (date +%s%N)

        # Calculate runtime
        set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

        if test $runtime_milliseconds -ge 1000
            set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
        else
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
        end

        # Clean up: remove the executable file
        rm $executable

    else
        echo (set_color red)Compilation failed.(set_color normal)
    end
end

# compiles and runs a Java program
function jrun
    # Check if at least one argument (the source file) is provided
    if test -z "$argv[1]"
        if set -q last_jrun_program
            set source_file $last_jrun_program
        else
            echo (set_color red)Usage: jrun <source_file.java> [args...] or jrun to rerun the last program(set_color normal)
            return 1
        end
    else
        set source_file $argv[1]
        # Save the last run program using a universal variable
        set -U last_jrun_program $source_file
    end

    set classname (basename $source_file '.java')

    # Compile the Java program
    javac $source_file

    # Check if compilation was successful
    if test $status -eq 0
        echo (set_color -u '#92d8ff')Compilation successful. Running $classname...(set_color normal)

        # Record start time in nanoseconds
        set start_time (date +%s%N)

        # Run the compiled Java program with the additional arguments
        java $classname $argv[2..-1]

        # Record end time in nanoseconds
        set end_time (date +%s%N)

        # Calculate runtime
        set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

        if test $runtime_milliseconds -ge 1000
            set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
        else
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
        end

    else
        echo (set_color red)Compilation failed.(set_color normal)
    end
end

# runs a Python program
function prun
    # Check if at least one argument (the source file) is provided
    if test -z "$argv[1]"
        if set -q last_prun_program
            set source_file $last_prun_program
        else
            echo (set_color red)Usage: prun <source_file.py> [args...] or prun to rerun the last program(set_color normal)
            return 1
        end
    else
        set source_file $argv[1]
        # Save the last run program using a universal variable
        set -U last_prun_program $source_file
    end

    # Check if the Python file exists
    if not test -f $source_file
        echo (set_color red)Error: File "$source_file" not found!(set_color normal)
        return 1
    end

    echo (set_color -u '#92d8ff')Running $source_file...(set_color normal)

    # Record start time in nanoseconds
    set start_time (date +%s%N)

    # Run the Python script with the additional arguments
    python3 $source_file $argv[2..-1]

    # Record end time in nanoseconds
    set end_time (date +%s%N)

    # Calculate runtime
    set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

    if test $runtime_milliseconds -ge 1000
        set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
        echo (set_color green)Script concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
    else
        echo (set_color green)Script concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
    end
end

# compiles and runs a program in assembly
function arun
    # Check if at least one argument (the source file) is provided
    if test -z "$argv[1]"
        if set -q last_arun_program
            set source_file $last_arun_program
        else
            echo (set_color red)Usage: arun <source_file.s> [args...] or arun to rerun the last program(set_color normal)
            return 1
        end
    else
        set source_file $argv[1]
        # Save the last run program using a universal variable
        set -U last_arun_program $source_file
    end

    set executable (basename $source_file '.s')

    # Compile the assembly program using gcc with the no-PIE option
    gcc -no-pie -o $executable $source_file

    # Check if compilation was successful
    if test $status -eq 0
        echo (set_color -u '#92d8ff')Compilation successful. Running $executable...(set_color normal)

        # Record start time in nanoseconds
        set start_time (date +%s%N)

        # Run the compiled program with the additional arguments
        ./$executable $argv[2..-1]

        # Record end time in nanoseconds
        set end_time (date +%s%N)

        # Calculate runtime
        set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

        if test $runtime_milliseconds -ge 1000
            set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
        else
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
        end

        # Clean up: remove the executable file
        rm $executable

    else
        echo (set_color red)Compilation failed.(set_color normal)
    end
end

# runs a Racket program
function rrun
    # Check if at least one argument (the source file) is provided
    if test -z "$argv[1]"
        if set -q last_rrun_program
            set source_file $last_rrun_program
        else
            echo (set_color red)Usage: rrun <source_file.rkt> [args...] or rrun to rerun the last program(set_color normal)
            return 1
        end
    else
        set source_file $argv[1]
        # Save the last run program using a universal variable
        set -U last_rrun_program $source_file
    end

    # Check if the Racket file exists
    if not test -f $source_file
        echo (set_color red)Error: File "$source_file" not found!(set_color normal)
        return 1
    end

    echo (set_color -u '#92d8ff')Running $source_file...(set_color normal)

    # Record start time in nanoseconds
    set start_time (date +%s%N)

    # Run the Python script with the additional arguments
    racket $source_file $argv[2..-1]

    # Record end time in nanoseconds
    set end_time (date +%s%N)

    # Calculate runtime
    set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

    if test $runtime_milliseconds -ge 1000
        set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
        echo (set_color green)Script concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
    else
        echo (set_color green)Script concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
    end
end


# saves the current directory then navigates to it
# used to sync another terminal with  the current directory
function reloc
    # Check if the first argument is "-c" to clear the saved path
    if [ "$argv[1]" = "-c" ]
        # Clear the universal variable
        set -e saved_wsl_path
        echo "Saved directory cleared."
    else
        # Check if the universal variable 'saved_wsl_path' is set and not empty
        if set -qU saved_wsl_path; and test -n "$saved_wsl_path"
            # 'cd' to the saved directory and clear the variable
            cd $saved_wsl_path
            # Optionally, clear the screen after changing the directory
            clear
            # Clear the universal variable
            set -e saved_wsl_path
        else
            # Save the current directory to the universal variable 'saved_wsl_path'
            set -U saved_wsl_path (pwd)
            set last_part (basename $saved_wsl_path)
            echo (set_color '#92d8ff')Current directory saved: (set_color -i yellow)$last_part(set_color normal)
        end
    end
end

# Updates /etc/nixos to the latest state from its GitHub repo and rebuilds the system using the flake
function rbld
    # Pull latest changes from the GitHub repo in /etc/nixos
    echo (set_color -u '#92d8ff')Pulling latest changes from GitHub in /etc/nixos...(set_color normal)
    pushd /etc/nixos
    sudo git pull
    popd
    echo (set_color -u '#92d8ff')Rebuilding NixOS with flake...(set_color normal)
    sudo nixos-rebuild switch --flake /etc/nixos#
    echo (set_color green)NixOS update complete!(set_color normal)
end

function rbld-local
    # Pull latest changes from the GitHub repo in /etc/nixos
    echo (set_color -u '#92d8ff')Pulling latest changes from GitHub in /etc/nixos...(set_color normal)
    pushd /etc/nixos
    echo (set_color -u '#92d8ff')Rebuilding NixOS with flake...(set_color normal)
    sudo nixos-rebuild switch --flake /etc/nixos#
    echo (set_color green)NixOS update complete!(set_color normal)
end
