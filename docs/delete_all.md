NAME:

    delete

  SYNOPSIS:

    hekate delete_all --region us-west-2 --environment development --application mycoolapp

  DESCRIPTION:

    deletes all secrets for the give environment

  OPTIONS:
        
    --application STRING 
        The application name for which the imported secrets will be used
        
    --environment STRING 
        The rails environment for which the imported secrets will be used. Defaults to development
        
    --region STRING 
        The aws region to import into. Defaults to ENV["AWS_REGION"] || "us-east-1"
