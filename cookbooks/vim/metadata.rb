maintainer        "Sebastian Probst Eide"
maintainer_email  "sebastian.probst.eide@gmail.com"
license           "Apache 2.0"
description       "Installs vim and Sebastian's vim configs"
version           "0.0.1"
recipe            "vim", "Installs vim"
recipe            "git::seb_friendly", "Installs vim plugins and configuration as used by myself"

%w{ ubuntu debian arch}.each do |os|
  supports os
end

%w{ git }.each do |cb|
  depends cb
end
