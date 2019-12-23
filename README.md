Scalingo Nginx Buildpack
========================

This buildpack aims at installing a nginx instance and let you configure it at
your convenance.

## Defining the Version

By default we're installing the latest available version of Nginx, but if you
want to use a specific version, you can define the environment variable `NGINX_VERSION`

```console
$ scalingo env-set NGINX_VERSION=1.8.0
```

## Configuration

The buildpack is expecting a configuration file at the root of the project
which can be:

* `nginx.conf`: Simple configuration file
* `nginx.conf.erb`: Template to generate the configuration file

If the template is found, it will be rendered as configuration file, it let you use environment
variables as in the following examples.

## Discouraged Directives

The following directives should not be used in you configuration file: `listen`, `access_log`, `error_log` and `server_name`.

## Configuration Examples

### Split Traffic to 2 APIs

```
location /api/v1 {
  proxy_pass https://api-v1-app.scalingo.io;
}

location /api/v2 {
  proxy_pass https://api-v2-app.scalingo.io;
}
```

Using a template to give the names of the app from the environment: `nginx.conf.erb`

```
location /api/v1 {
  proxy_pass <%= ENV["API_V1_BACKEND"] %>;
}

location /api/v2 {
  proxy_pass <%= ENV["API_V2_BACKEND"] %>;
}
```

Use nginx configuration:
[https://nginx.org/en/docs/](https://nginx.org/en/docs/) to get details about
how to configure your app.

## Advanced Information

The configuration file you have to provide is at the `server` level, if you need
to add something at the `http` level, please open an [issue](https://github.com/Scalingo/nginx-buildpack/issues/new)
or a [pull request](https://github.com/Scalingo/nginx-buildpack/pulls/new) and we'll discuss it.
