NAME:

    export

  SYNOPSIS:

    hekate export --region us-west-2 --environment development --application mycoolapp --file .env

  DESCRIPTION:

    exports Amazon SSM parameters to a .env formatted file

  OPTIONS:
        
    --application STRING 
        The application name for which the imported secrets will be used
        
    --environment STRING 
        The rails environment for which the imported secrets will be used. Defaults to development
        
    --region STRING 
        The aws region to import into. Defaults to ENV["AWS_REGION"] || "us-east-1"
        
    --file STRING 
        The dotenv formatted file to export to
