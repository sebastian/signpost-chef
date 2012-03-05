# --- Make the vim installation have all the configurations I like :) ---
package "exuberant-ctags" do
  action :install
end

package "curl" do
  action :install
end

execute "Make vim Sebastian friendly" do
  command "curl https://raw.github.com/sebastian/vim-config/master/quickinstall.sh | sh"
  action :run
  # Only run if the user doesn't already have a ~/.vim directory
  not_if "test -d ~/.vim"
end
