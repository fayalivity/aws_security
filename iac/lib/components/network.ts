import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import {
    aws_ec2 as ec2
} from 'aws-cdk-lib';
import { DEPLOY_ID, VPC_CIDR } from '../../utils/constants';

export class Network extends Construct {
    public readonly vpc: ec2.IVpc;
    public readonly publicSubnets: ec2.ISubnet[];
    public readonly privateSubnets: ec2.ISubnet[];

    constructor(scope: Construct, id: string) {
        super(scope, id);

        this.vpc = new ec2.Vpc(scope, 'vpc-lab', {
            ipAddresses: ec2.IpAddresses.cidr(VPC_CIDR),
            vpcName: DEPLOY_ID,
            vpnGateway: false,
            natGateways: 0,
            createInternetGateway: false,
            subnetConfiguration: [{
                name: `subnet-${DEPLOY_ID}-public`,
                subnetType: ec2.SubnetType.PUBLIC,
                cidrMask: 24
            },
            {
                name: `subnet-${DEPLOY_ID}-private`,
                subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
                cidrMask: 24
            }]
        });
        
        this.vpc.applyRemovalPolicy(cdk.RemovalPolicy.DESTROY);

        // this.publicSubnets = []
        // PUBLIC_CIDR_LIST.forEach((cidr, index) => {
        //     const subnet: ISubnet = new ec2.Subnet(scope, `publi-subnet-${AZ_LIST[index]}`, {
        //         vpcId: this.vpc.vpcId,
        //         cidrBlock: cidr,
        //         availabilityZone: AZ_LIST[index],

        //     });
        // this.publicSubnets.push(subnet);
        // });


    }

}