import boto3


def get_parameter(param_name):
    """
    This function reads a secure parameter from AWS' SSM service. The request must be passed a valid parameter name,
    as well as temporary credentials which can be used to access the parameter.
    :param param_name:
    :return: parameter value
    """
    ssm = boto3.client('ssm')

    response = ssm.get_parameter(
        Name=param_name,
        WithDecryption=True
    )
    return response['Parameter']['Value']