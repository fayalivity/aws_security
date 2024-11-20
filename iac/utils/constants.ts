export const PROJECT = process.env.CDK_PROJECT || 'security-lab'
export const ENV = process.env.CDK_ENV || 'test';
export const DEPLOY_ID = `${PROJECT}-${ENV}`
export const VPC_CIDR = '10.0.0.0/16';
export const PRIVATE_CIDR_LIST = [
    '10.0.1.0/24',
    '10.0.2.0/24'
];
export const PUBLIC_CIDR_LIST = [
    '10.0.3.0/24',
    '10.0.4.0/24'
];
export const AZ_LIST = [
    'eu-west-1a',
    'eu-west-1b'
];
