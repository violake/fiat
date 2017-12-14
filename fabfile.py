from fabric.api import task, env, lcd, local, settings
from libdeploy import *
import os

env.use_ssh_config = True

params = {
    "username"       : "app",
    "theme"          : "notheme",
    "projectname"    : "fiat",
    "ruby_version"   : "2.4.0",
    
    "tar_strip_components" : 1,
    "number_of_releases"   : 10,   #number of releases kept in releases folder
    "roll_back_switch"     : True,

    "mariadb_type"   : "client",  #mariadb types:  "client", "server"
    "mariadb_version": "10.1",
    #"nodejs_version" : "8.x",
    ####### shared_files format:  [[ folder, [ shared file name list], type ], ... ] 
    ####### or left empty []
    "shared_files"   :  [ ["config", ["application","database", "rabbitmq", "fiat", "secrets", "cable", "fund_source"], "yml"],],
    "shared_path"    :  [ "vendor/bundle", "vendor/cache" ],
    "post_commands"  :  ["bundle install --with=production --without=\"development test\" --path=vendor/bundle",
                        "mkdir -p tmp",
                        "touch tmp/restart.txt"],



    ####  default settings    #############################################
    ## local_project_path = <current path running your fabfile>          ##
    ## local_release_path = <local_project_path>/release                 ##
    ## remote_install_path = /home/<username>/<projectname>              ##
    ## remote_shared_path  = /home/<username>/<projectname>/shared       ##
    ## remote_current_path = /home/<username>/<projectname>/current      ##
    ## remote_release_path = /home/<username>/<projectname>/releases     ##
    ## nginx_makefile = <local_project_path>/makefile_for_nginx          ##
    ########################################################################

    ####  customizedfull path required  ###########################################
    "customized_local_project_path"  : "",
    "customized_local_release_path"  : os.path.join(os.getcwd(), "releases"),
    "customized_remote_install_path" : "",
    "customized_remote_shared_path"  : "",
    "customized_remote_current_path" : "",
    "customized_remote_release_path" : "",
    "customized_shared_symlinks" : [],    
    ### sample [["<symbol link>", "<real location>"]]  
    ### Attention !!!! : if no customized_config_symlinks,  left it empty as []  not [[]]

}

params = update_params(params)


@task
def init_sys():
    '''System Provisioning'''
    env.user = "ubuntu"
    update_system()
    #setup_firewall()
    install_amqp_tools()
    install_supervisor()
    install_mariadb_dev(params) 
    #install_nodejs(params)
    add_user(params["username"])

@task
def install_deps():
    '''Install dependencies, create folders and config files'''
    env.user = params["username"]
    install_ruby(params)    
    setup_directories(params)
    create_config_files(params)

@task
def deploy(theme="notheme"):
    '''Deploy source code to server'''
    env.user = params["username"]
    if not theme=="notheme":
        params["theme"] = theme
        tmp_params = update_params(params)
        tmp_params["config_symlinks"].update(tmp_params["path_symlinks"])
        deploy_src(tmp_params)
    else:
        params["config_symlinks"].update(params["path_symlinks"])
        deploy_src(params)

@task
def check_version():
    '''Check current release version'''
    check_ver(params)


@task
def get_last_release():
    '''get latest release package, for DevOps CI/CD '''
    with lcd(params["local_release_path"]):
        releasefiles = local("ls -t *.tar.gz",capture=True).split()
        if len(releasefiles)>=1:
            filename = releasefiles[0].split(".")[0]
            with open('last_release', 'w+') as f:
                f.write(filename)
        else:
            print "No tarfile found! Please create your tarfile first"      


