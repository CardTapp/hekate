NAME:

    put

  SYNOPSIS:

    hekate put --region us-west-2 --environment development --application mycoolapp --key somekey --value somevalue

  DESCRIPTION:

    adds a new environment secret and value

  OPTIONS:
        
    --application STRING 
        The application name for which the imported secrets will be used
        
    --environment STRING 
        The rails environment for which the imported secrets will be used. Defaults to development
        
    --region STRING 
        The aws region to import into. Defaults to ENV["AWS_REGION"] || "us-east-1"
        
    --key STRING 
        The environment name of the secret to store
        
    --value STRING 
        The environment value of the secret to store
