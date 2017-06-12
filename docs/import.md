NAME:

    import

  SYNOPSIS:

    hekate import --region us-west-2 --environment development --application mycoolapp --file .env

  DESCRIPTION:

    imports a .env formatted file into Amazon SSM

  OPTIONS:
        
    --application STRING 
        The application name for which the imported secrets will be used
        
    --environment STRING 
        The rails environment for which the imported secrets will be used. Defaults to development
        
    --region STRING 
        The aws region to import into. Defaults to ENV["AWS_REGION"] || "us-east-1"
        
    --file STRING 
        The dotenv formatted file to import
