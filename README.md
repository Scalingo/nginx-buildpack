# Scalingo Nginx Buildpack

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
* `servers.conf.erb`: (optional) Let you configure your nginx instance at the `http` level if required

If the template is found, it will be rendered as configuration file, it let you use environment
variables as in the following examples.

## Discouraged Directives

The following directives should not be used in you configuration file: `listen`, `access_log`, `error_log` and `server_name`.

## Configuration Examples (`nginx.conf`)

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

## Configuration Examples (`servers.conf.erb`)

When using this configuration method, the previous one won't be considered,
they are exclusive.


###  Setup throttling with a `limit_req_zone`

```
# instruction at the http level like
limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;

server {
    server_name localhost;
    listen <%= ENV['PORT'] %>;

    charset utf-8;
    location {
        limit_req zone=one burst=5;
        proxy_pass http://<%= ENV["API_V1_BACKEND"] %>;
    }
}
```

### Multiple domains configuration

```
server {
    server_name front.example.com;
    listen <%= ENV['PORT'] %>;

    charset utf-8;
    location {
        proxy_pass http://<%= ENV["FRONT_BACKEND"] %>;
    }
}

server {
    server_name api.example.com;
    listen <%= ENV['PORT'] %>;

    charset utf-8;
    location {
        proxy_pass http://<%= ENV["API_BACKEND"] %>;
    }
}
```

## Using Nginx as a WAF with ModSecurity and the OWASP Core Rule Set

### Glossary:

- **WAF**: Web Application Firewall. In a web architecture, this component’s sole role is to filter inbound HTTP traffic by applying pre-defined rules. Some WAF are adaptive and “learn” from patterns, some are static and need to have their rules updated.
- **ModSecurity**: embedded interpreter for query filtering. It is deployed as a plugin in most web servers (Nginx, Apache, etc…)
- **CRS**: Core Rule Set, it's the set of community rules edited under the OWASP governance that aim to protect against the Top 10 threat for web applications.

### How-to deploy and test on Scalingo

- Create an nginx application on Scalingo: [https://doc.scalingo.com/platform/deployment/buildpacks/nginx](https://doc.scalingo.com/platform/deployment/buildpacks/nginx#purpose-of-this-buildpack)
- Set the environment variable `ENABLE_MODSECURITY=true` and do a redeploy the app. For that create an empty commit and push it to your scalingo remote.
  Several additional actions will be done in this new deployment:
  
    1. ModSecurity and its dependencies will be installed
    2. Default configuration for ModSecurity will be enabled

- You can test that the CRS are active with the following request:
    
    `curl -X INVALID_HTTP_METHOD https://$YOUR_APP_NAME.osc-fr1.scalingo.io -v`
    
    You should expect a 403 forbidden answer such as the following:
    
    ```bash
    > INVALID_HTTP_METHOD / HTTP/2
    > Host: $YOUR_APP_NAME.osc-fr1.scalingo.io
    > User-Agent: curl/7.64.1
    > Accept: */*
    >
    * Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
    < HTTP/2 403
    < date: Tue, 31 May 2022 13:58:46 GMT
    < content-type: text/html; charset=utf-8
    < content-length: 146
    < x-request-id: 343e6a24-640e-499a-9dfe-f5dbb636ef45
    < strict-transport-security: max-age=31536000
    <
    <html>
    <head><title>403 Forbidden</title></head>
    <body>
    <center><h1>403 Forbidden</h1></center>
    <hr><center>nginx</center>
    </body>
    </html>
    ```
    

### Updating the CRS rules

- You have to redeploy the application, the latest stable version is downloaded during the build phase. For that, create an empty commit on your repository and push it to the scalingo remote

Note: you can manually set a specific version of the CRS by setting the variable `MODSECURITY_CORE_RULE_SET_VERSION` (default is `3.3.2` at the day of May 31, 2022)

### Updating the ModSecurity version

- Upon each deployment, the latest packaged version of modsecurity is used. Scalingo does not provide any guarantee in term of packagin time after each release, get in touch with the support if you need a specific version.

Note: minimal supported version is 3.0.6

### How-to add a custom rule

- Note that, on Scalingo, the root of your repository is deployed on `/app`
- Create a file to hold all the custom rules you will write and reference it in the nginx config file like so:

```bash
##############################################
# in nginx.conf.erb file
# This file is written in Nginx config language

location / {
    modsecurity on; # Enable ModSecurity on /
    modsecurity_rules_file /app/custom-rules.modsecurity; # load custom rules file
    # (...)
    # The rest of your NGINX config file
}

##############################################
# in custom-rules.modsecurity file:
# This file is written in ModSecurity config language

# CUSTOM RULE id:1234
# IF query or body parameter contains a parameter named “param1” which contains “test”
# THEN block the request with a code 403 and log the event
SecRule ARGS:param1 "@contains test" \
	"id:1234,\
	 deny,\
	 log,\
	 status:403,\
	 severity: 'CRITICAL',\
	 tag: 'custom-rule',\
	 msg: 'this is the log message you will see',\
	 logdata: '%{MATCHED_VAR_NAME}=%{MATCHED_VAR}'"
```

- Note: The id:1234 is an arbitrary number, you can use any number < 100000 (see: https://coreruleset.org/docs/rules/ruleid/)
- Note on logdata: See here the list of all variables you can use: https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#variables

### How-to disable a CRS rule

If you identified a CRS rule that you want to disable, you can use this modsecurity directive to disable it:

```bash
##############################################
# in nginx.conf.erb file:
# This file is written in Nginx config language

location / {
    modsecurity on; # Enable ModSecurity on /
    modsecurity_rules_file /app/custom-rules.modsecurity; # load custom rules from file
    # 
    # (...)
    # Rest of your config file
}

##############################################
# in custom-rules.modsecurity file:
# This file is written in the ModSecurity config language

# Rule 911100 filters unknown HTTP methods. We want to allow exotic HTTP methods
SecRuleRemoveId 911100
```


### Customizing configuration

A few environment variables can be tweaked in order to configure ModSecurity

* `MODSECURITY_DEBUG_LOG_LEVEL` (default `0`): from `0` to `9` (no log to super verbose)
* `MODSECURITY_AUDIT_LOG_LEVEL` (default `Off`): Either `On` (all requests), or `RelevantOnly` (requests returning 4XX and 5XX status code)

### Usage with a minimal Stack

Compatibility: `scalingo-22-minimal` only

If this buildpack is used with a minimal stack , the following dependencies should be installed through the APT buildpack:

```
libxml2
libssl3
libpcre3
libcurl4
```
