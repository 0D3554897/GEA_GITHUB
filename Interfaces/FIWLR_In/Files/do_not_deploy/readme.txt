FIWLR jobs (.sql files) presented in the directory were received from production, 
but since job's content is not CC contolled it is possible to have it different on production.

SSIS configuration files  (.dtsConfig) where used on development to pass id/password to SSIS packages
should be modified (some connection strings and all id/passwords) before use on SIT and Production

Please consult production when an update is developed. 