NAME:

    delete

  SYNOPSIS:

    hekate delete --region us-west-2 --environment development --application mycoolapp --key somekey

  DESCRIPTION:

    deletes an a parameter

  OPTIONS:
        
    --application STRING 
        The application name for which the imported secrets will be used
        
    --environment STRING 
        The rails environment for which the imported secrets will be used. Defaults to development
        
    --region STRING 
        The aws region to import into. Defaults to ENV["AWS_REGION"] || "us-east-1"
    
    --key STRING
        The name of the secret to delete
