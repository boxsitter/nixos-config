# home/leyton/default.nix
# Shared user configuration across all systems

{ config, pkgs, ... }:

{
  home.stateVersion = "24.11";
  
  # Basic user info
  home.username = "leyton";
  home.homeDirectory = "/home/leyton";

  # Fish shell with your custom functions and aliases
  programs.fish = {
    enable = true;
    
    shellInit = ''
      # Starship prompt
      starship init fish | source
      
      # Adjust color theme
      set fish_color_error \#c56a72
      
      # Remove greeting message
      set fish_greeting ''
    '';
    
    # Clean aliases using shellAliases (cleaner than inline functions for simple ones)
    shellAliases = {
      ls = "eza -F";
      la = "eza -Fa";
      l = "eza -lh --no-user --no-time";
      ll = "eza -lah --no-user --no-time";
      g = "git";
      neo = "neofetch";
      cl = "clear";
    };
    
    functions = {
      # Remove right prompt (timestamps)
      fish_right_prompt = "";
      
      # VS Code shortcut (will be different per-host)
      c = {
        description = "VS Code shortcut";
        wraps = "code";
        body = "code $argv";
      };
      
      # Here function - outputs escaped cd command for current directory
      here = {
        wraps = "pwd";
        body = ''
          set output (pwd)
          set output (string replace -a ' ' '\ ' $output)
          set output (string replace -a '(' '\(' $output)
          set output (string replace -a ')' '\)' $output)
          echo "cd" $output
        '';
      };
      
      # Compile and run C programs
      crun = ''
        if test -z "$argv[1]"
          if set -q last_crun_program
            set source_file $last_crun_program
          else
            echo (set_color red)Usage: crun '<source_file.c>' '[args...]' or crun to rerun the last program(set_color normal)
            return 1
          end
        else
          set source_file $argv[1]
          set -U last_crun_program $source_file
        end

        set executable (basename $source_file '.c')
        gcc -o $executable $source_file

        if test $status -eq 0
          echo (set_color -u '#92d8ff')Compilation successful. Running $executable...(set_color normal)
          set start_time (date +%s%N)
          ./$executable $argv[2..-1]
          set end_time (date +%s%N)
          set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

          if test $runtime_milliseconds -ge 1000
            set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
          else
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
          end
          rm $executable
        else
          echo (set_color red)Compilation failed.(set_color normal)
        end
      '';
      
      # Compile and run C# programs
      csrun = ''
        if test -z "$argv[1]"
          if set -q last_csrun_program
            set source_file $last_csrun_program
          else
            echo (set_color red)Usage: csrun '<source_file.cs>' '[args...]' or csrun to rerun the last program(set_color normal)
            return 1
          end
        else
          set source_file $argv[1]
          set -U last_csrun_program $source_file
        end

        set executable (basename $source_file '.cs').exe
        mcs -out:$executable $source_file

        if test $status -eq 0
          echo (set_color -u '#92d8ff')Compilation successful. Running $executable...(set_color normal)
          set start_time (date +%s%N)
          mono $executable $argv[2..-1]
          set end_time (date +%s%N)
          set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

          if test $runtime_milliseconds -ge 1000
            set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
          else
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
          end
          rm $executable
        else
          echo (set_color red)Compilation failed.(set_color normal)
        end
      '';
      
      # Compile and run Java programs
      jrun = ''
        if test -z "$argv[1]"
          if set -q last_jrun_program
            set source_file $last_jrun_program
          else
            echo (set_color red)Usage: jrun '<source_file.java>' '[args...]' or jrun to rerun the last program(set_color normal)
            return 1
          end
        else
          set source_file $argv[1]
          set -U last_jrun_program $source_file
        end

        set classname (basename $source_file '.java')
        javac $source_file

        if test $status -eq 0
          echo (set_color -u '#92d8ff')Compilation successful. Running $classname...(set_color normal)
          set start_time (date +%s%N)
          java $classname $argv[2..-1]
          set end_time (date +%s%N)
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
      '';
      
      # Run Python programs
      prun = ''
        if test -z "$argv[1]"
          if set -q last_prun_program
            set source_file $last_prun_program
          else
            echo (set_color red)Usage: prun '<source_file.py>' '[args...]' or prun to rerun the last program(set_color normal)
            return 1
          end
        else
          set source_file $argv[1]
          set -U last_prun_program $source_file
        end

        if not test -f $source_file
          echo (set_color red)Error: File "$source_file" not found!(set_color normal)
          return 1
        end

        echo (set_color -u '#92d8ff')Running $source_file...(set_color normal)
        set start_time (date +%s%N)
        python3 $source_file $argv[2..-1]
        set end_time (date +%s%N)
        set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

        if test $runtime_milliseconds -ge 1000
          set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
          echo (set_color green)Script concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
        else
          echo (set_color green)Script concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
        end
      '';
      
      # Compile and run Assembly programs
      arun = ''
        if test -z "$argv[1]"
          if set -q last_arun_program
            set source_file $last_arun_program
          else
            echo (set_color red)Usage: arun '<source_file.s>' '[args...]' or arun to rerun the last program(set_color normal)
            return 1
          end
        else
          set source_file $argv[1]
          set -U last_arun_program $source_file
        end

        set executable (basename $source_file '.s')
        gcc -no-pie -o $executable $source_file

        if test $status -eq 0
          echo (set_color -u '#92d8ff')Compilation successful. Running $executable...(set_color normal)
          set start_time (date +%s%N)
          ./$executable $argv[2..-1]
          set end_time (date +%s%N)
          set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

          if test $runtime_milliseconds -ge 1000
            set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
          else
            echo (set_color green)Program concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
          end
          rm $executable
        else
          echo (set_color red)Compilation failed.(set_color normal)
        end
      '';
      
      # Run Racket programs
      rrun = ''
        if test -z "$argv[1]"
          if set -q last_rrun_program
            set source_file $last_rrun_program
          else
            echo (set_color red)Usage: rrun '<source_file.rkt>' '[args...]' or rrun to rerun the last program(set_color normal)
            return 1
          end
        else
          set source_file $argv[1]
          set -U last_rrun_program $source_file
        end

        if not test -f $source_file
          echo (set_color red)Error: File "$source_file" not found!(set_color normal)
          return 1
        end

        echo (set_color -u '#92d8ff')Running $source_file...(set_color normal)
        set start_time (date +%s%N)
        racket $source_file $argv[2..-1]
        set end_time (date +%s%N)
        set runtime_milliseconds (echo "scale=0; (($end_time - $start_time) + 999999) / 1000000" | bc)

        if test $runtime_milliseconds -ge 1000
          set runtime_seconds (echo "scale=3; $runtime_milliseconds / 1000" | bc)
          echo (set_color green)Script concluded. (set_color '#ffff85')Runtime: $runtime_seconds seconds.(set_color normal)
        else
          echo (set_color green)Script concluded. (set_color '#ffff85')Runtime: $runtime_milliseconds milliseconds.(set_color normal)
        end
      '';
      
      # Relocate function - saves/restores directory
      reloc = ''
        if test "$argv[1]" = "-c"
          set -e saved_wsl_path
          echo "Saved directory cleared."
        else
          if set -qU saved_wsl_path; and test -n "$saved_wsl_path"
            cd $saved_wsl_path
            clear
            set -e saved_wsl_path
          else
            set -U saved_wsl_path (pwd)
            set last_part (basename $saved_wsl_path)
            echo (set_color '#92d8ff')Current directory saved: (set_color -i yellow)$last_part(set_color normal)
          end
        end
      '';
    };
  };

  # Starship prompt with your custom config
  programs.starship = {
    enable = true;
    settings = {
      container.disabled = true;
      python.disabled = true;
    };
  };

  # Git configuration (you can customize this)
  programs.git = {
    enable = true;
    userName = "Leyton Houck";
    userEmail = "your@email.com";  # Update this
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # User packages (available across all systems)
  home.packages = with pkgs; [
    # These are already in core.nix but can be user-specific too
    neofetch
    eza
    bc  # For the runtime calculations in your functions
  ];
}
