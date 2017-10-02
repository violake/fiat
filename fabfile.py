from fabric.api import task, env, lcd, local, settings
from libdeploy import *
import os

env.use_ssh_config = True

params = {
    "username"       : "app",
    "projectname"    : "fiat",
    "ruby_version"   : "2.4.0",
    "nodejs_version" : "8.x",

    "mariadb_type"   : "client",  #mariadb types:  "client", "server"
    "mariadb_version": "10.1",
    
    "tar_strip_components" : 1,
    "number_of_releases"   : 10,   #number of releases kept in releases folder
    "roll_back_switch"     : True,

    "nginx_makefile"  : "makefile_for_nginx",

    ####### shared_files format:  [[ folder, [ shared file name list], type ], ... ] 
    ####### or left empty []
    "shared_files"   :  [ ["config", ["database", "rabbitmq", "fiat", "secrets", "cable"], "yml"],],
    "shared_path"    :  [ "vendor/bundle", "vendor/cache" ],
    "post_commands"  :  ["bundle install --with=production --without=\"development test\" --path=vendor/bundle"],
    
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
    "customized_local_release_path"  : "",
    "customized_remote_install_path" : "",
    "customized_remote_shared_path"  : "",
    "customized_remote_current_path" : "",
    "customized_remote_release_path" : "",

    "customized_shared_symlinks" : [],    
    ### sample [["<symbol link>", "<real location>"]]  
    ### Attention !!!! : if no customized_config_symlinks,  left it empty as []  not [[]]

    "customized_nginx_installation_makefile" : "",

}

params = update_params(params)


@task
def init_sys():
    '''system initialization'''
    env.user = "ubuntu"
    update_system()
    setup_firewall()
    install_amqp_tools()
    install_supervisor()
    install_mariadb_dev(params) 
    install_nginx(params)
    install_parity()
    install_nodejs(params)
    add_user(params["username"])

@task
def install_deps():
    '''install prerequisites, create folders and config files'''
    env.user = params["username"]
    install_ruby(params["ruby_version"])    
    setup_directories(params)
    create_config_files(params)

@task
def deploy():
    '''deploy source code'''
    env.user = params["username"]
    params["config_symlinks"].update(params["path_symlinks"])
    deploy_src(params)


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


