# Site Reliability Tools


```txt
app
|_ site-reliability-tools
    |_ logging
    |_ maintenance
    |_ observability
    |_ security
|_ ...
```

Site reliability tools container Docker Compose files to be used within a Docker Swarm instance. To isolate management functions from application services, all tools are deploy within a separate stack from application services. 
