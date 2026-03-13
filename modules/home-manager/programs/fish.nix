# modules/home-manager/programs/fish.nix
# Fish shell configuration

{ ... }:

{
  programs.fish = {
    enable = true;
    shellInit = ''
      starship init fish | source
      set fish_greeting ""
    '';
    shellAliases = {
      # Modern replacements for core utilities
      ls = "eza";
      ll = "eza -lah";
      la = "eza -a";
      lt = "eza --tree";
      tree = "eza --tree";
      cat = "bat";
      find = "fd";
      top = "htop";
      ff = "fastfetch";
    };
    functions = {
      mc = ''
        switch $argv[1]
          case console
            # Kill existing session if it exists
            tmux kill-session -t minecraft 2>/dev/null
            
            tmux new-session -d -s minecraft
            tmux split-window -h -t minecraft -p 25
            tmux send-keys -t minecraft:0.0 'sudo journalctl -u minecraft-server-main -f --no-hostname -o cat' C-m
            tmux send-keys -t minecraft:0.1 'mcrcon -H localhost -P 25575 -p minecraft -t' C-m
            tmux select-pane -t minecraft:0.1
            tmux attach-session -t minecraft
          case cmd
            mcrcon -H localhost -P 25575 -p minecraft -t
          case logs
            sudo journalctl -u minecraft-server-main -f --no-hostname -o cat
          case restart
            sudo systemctl restart minecraft-server-main
          case stop
            sudo systemctl stop minecraft-server-main
          case start
            sudo systemctl start minecraft-server-main
          case status
            sudo systemctl status minecraft-server-main
          case help
            echo "Usage: mc <command> [args...]"
            echo "Commands:"
            echo "  console  - Open interactive console with logs"
            echo "  cmd      - Enter interactive server command mode"
            echo "  logs     - View server logs"
            echo "  restart  - Restart server"
            echo "  stop     - Stop server"
            echo "  start    - Start server"
            echo "  status   - Show server status"
            echo "  help     - Show this help message"
            echo ""
            echo "Any other input will be sent as a command to the server:"
            echo "  mc say hello       - Sends 'say hello' to server"
            echo "  mc tp player 0 0 0 - Sends 'tp player 0 0 0' to server"
          case '*'
            # Send everything as a command to the server
            mcrcon -H localhost -P 25575 -p minecraft (string join ' ' $argv)
        end
      '';
    };
  };
}
