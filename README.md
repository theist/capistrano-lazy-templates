# Capistrano Lazy Templates

[![Gem Version](https://badge.fury.io/rb/capistrano-lazy-templates.svg)](http://badge.fury.io/rb/capistrano-lazy-templates)

Helping tasks to download and upload server files or ERB templates in capistrano  v3

This gem gives capistrano tasks to mantain a set of files to upload and download to the servers, separated by role and stage.

## Requirements

- Capistrano >= 3
- Ruby >= 2.0

## Installation

Add it to the gemfile, better suits on the development or deployment group

    gem 'capistrano-lazy-templates'

Once installed uning bundler an after creating a deploy recipe with capistrano, edit the Capfile and add a line to load gem's tasks

    require 'capistrano-lazy-templates'

## Configuration


There are two variables to set and configure the behavior if this gem

    set :template_dir, 'config/templates'

This sets the base directory for storing the files it downloads or uploads. The files will be stored in `template_dir/<stage>/<role>/` in the same locations they are as if this path where the root of the server filesystem.

That path should exists before start downloading files.

    set :role_templates, %w(all)

This capistrano variable spects an array of roles, ideally the same roles you have defined in your deploy file. It defines what roles it will iterate for uploading files.

The role all in capistrano is a role which match all the hosts.

## Usage

Once the gem is properly loaded it share three tasks on the capistrano_lazy_templates namespace. These tasks aren't chained to any other tasks so it won't fire unles you call explicitly to them.

### Downloading Files

There are two task for downloading files. The `get` task lets you to specify a file (or directory) you want to take from the servers. 

    cap production lazy_templates:get FILE=/etc/nginx/nginx.conf ROLE=web

You must specify a valid file via the `FILE` environment variable, and you can specify a role to assign that download, using the `ROLE` environment variable. If you don't specify a role it will default to `:all`

Once launched the file specified will get downloaded to `template_dir/<stage>/<role>/` path, with all its path unouched. The previous example will leave the file specified on one of the servers which belongs to "web" role in

    config/templates/production/web/etc/nginx/nginx.conf

the path config/templates/production/web must exists before download, but from there all the path necesary to store the server file will be created.

#### Directories

If the file specified in `FILE` environment variable is a directory in the target server, the task will recursively download all the regular files it finds from that path. 

#### File Lists

Instead of specify manually each file you want to download you can use the task `:lazy_templates:get_file_list` using that instead, the value you specify in `FILE` environment variable will be interpreted as a local file for read the files or directories to download, just like the `lazy_templates:get` task.

#### Limitations

- `get` and `get_file_list` tasks cannot read nothing that the deploy user cannot read, so if it finds a file that won't be readed it will skip it and continue downloading the next one. 

- These task will not download empty directories or directories without enough permissions to be traversed.

### Uploading Files

The reverse of getting files from the server is the `capistrano_lazy_templates:upload_files` task. It will upload the role specified or all the present roles to each server in the different roles.

    cap production lazy_templates:upload_files

This examle will iterate thru all the declared roles in `role_templates` uploading all the files it found in the local template dir. 

You can specify to do it just for the servers on one role using 

    cap production lazy_templates:upload_files ROLE=web

If you specify the role `all` the files in the `template_folder/stage/all` will be uploaded to all servers.

#### Using ERB templates

The task checks for the extension .erb in the locally stored files. If it finds it it will compute the template as an ERB template before uploading it. It will be renamed without the erf file extension on the destination.

You can fetch capistrano's setted variables in the ERB templates using `fetch(:variable)` as usual.

#### Limitations

- obviously it can not upload ERB templates whitout processing it, as ERB templates are interpreted before upload. (Surely you'll get a template error if you try to do it)

- copies are made by root so if there's no file on the destination machine the file created will belong to root:root an will have restrictive permissions

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

