import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as fs from 'fs';
import { group } from 'console';

interface UserRecord {
  username: string;
  email: string;
}

export class UsersStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const inFile: string = '../data/user_list'

    const users: UserRecord[] = this.parseUserFile(inFile);
    
    const accountId = cdk.Aws.ACCOUNT_ID;

    const userAccessDetails: Array<{ username: string; email: string; password: string; accountId: string }> = [];
    
    const iamGroup = new iam.Group(this, 'UserGroup', {
      groupName: 'MICSI', // Nom du groupe IAM
    });
    
    const policy = new iam.Policy(this, `Policy-MICSI`, {
      policyName: `MICSI-Policy`,
      statements: [
        new iam.PolicyStatement({
          actions: [
            "ec2:RunInstances",
            "ec2:TerminateInstances",
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceStatus",
            "ec2:CreateVpc",
            "ec2:DescribeVpcs",
            "ec2:CreateSubnet",
            "ec2:DescribeSubnets",
            "ec2:CreateInternetGateway",
            "ec2:AttachInternetGateway",
            "ec2:CreateRouteTable",
            "ec2:AssociateRouteTable",
            "ec2:CreateRoute",
            "ec2:CreateSecurityGroup",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:CreateNatGateway",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DeleteLoadBalancer",
          ],
          resources: ["*"],
          conditions: {
            StringEquals: {
              "aws:RequestedRegion": "eu-west-1"
            }
          }
        }),
        new iam.PolicyStatement({
          actions: ["ec2:RunInstances"],
          resources: ["*"],
          conditions: {
            StringEquals: {
              "ec2:InstanceType": ["t2.micro", "t3.micro"],
              "aws:RequestedRegion": "eu-west-1"
            },
          },
        }),
      ],
    });

    policy.attachToGroup(iamGroup);
    iamGroup.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName('IAMUserChangePassword'));

    users.forEach((user) => {
      const password = this.generatePassword()
      const accessDetails = this.createUser(user, accountId, password, iamGroup)
      userAccessDetails.push(accessDetails);
    });

    this.writeAccessDetailsToTextFile(userAccessDetails);
  }

  private parseUserFile(filePath: string): UserRecord[] {
    const users: UserRecord[] = [];
    const lines = fs.readFileSync(filePath, 'utf8').split('\n');

    lines.forEach((line) => {
      if (line.trim() !== '') {
        const [firstname, lastname, email] = line.split(',');
        const username = `${firstname[0].toLowerCase()}${lastname.toLowerCase().replace(/\s+/g, '')}`;

        users.push({ username, email });
      }
    });

    return users;
  }

  private createUser(user: UserRecord, accountId: string, password: string, group: iam.Group): { username: string; password: string; accountId: string; email: string } {
    const iamUser = new iam.User(this, `User-${user.username}`, {
      userName: user.username,
      password: cdk.SecretValue.unsafePlainText(password),
      passwordResetRequired: true
    });

    group.addUser(iamUser);
    console.log(`Utilisateur ${user.username} créé avec succès.`);

    return {
      username: user.username,
      password,
      accountId,
      email: user.email
    };

  }

  private writeAccessDetailsToTextFile(userAccessDetails: Array<{ username: string; email: string; password: string; accountId: string }>) {
    const filePath = '../data/accessList';

    let fileContent = 'Access Details for IAM Users:\n\n';
    userAccessDetails.forEach((details) => {
      fileContent += `Username: ${details.username}\n`;
      fileContent += `Email: ${details.email}\n`;
      fileContent += `Password : ${details.password}\n`;
      fileContent += `Login URL: https://${details.accountId}.signin.aws.amazon.com/console\n`;
      fileContent += '\n';
    });

    fs.writeFileSync(filePath, fileContent, 'utf8');

    console.log(`Détails des utilisateurs écrits dans le fichier : ${filePath}`);
  }

  private generatePassword(): string {
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const specials = '!@#$%&?';
    
    // S'assurer que le mot de passe respecte les critères
    let password = '';
    password += lowercase.charAt(Math.floor(Math.random() * lowercase.length));
    password += uppercase.charAt(Math.floor(Math.random() * uppercase.length));
    password += digits.charAt(Math.floor(Math.random() * digits.length));
    password += specials.charAt(Math.floor(Math.random() * specials.length));
    
    // Ajouter des caractères supplémentaires pour atteindre la longueur souhaitée
    const allChars = lowercase + uppercase + digits + specials;
    for (let i = password.length; i < 12; i++) {
      password += allChars.charAt(Math.floor(Math.random() * allChars.length));
    }

    // S'assurer qu'il n'y a pas de point (.)
    password = password.replace('.', '');

    // Mélanger le mot de passe
    password = password.split('').sort(() => Math.random() - 0.5).join('');
    return password;
  }
}
