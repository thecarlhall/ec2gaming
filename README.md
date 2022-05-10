# ec2gaming - EC2 Gaming on macOS

Provides command line tools that makes gaming on EC2 simple and reliable. Includes steps to create an AMI that requires no intervention on startup, allows Steam remote installs and minimizes the amount of time game installs take.

Full documentation is available on the [wiki](https://github.com/DanielThomas/ec2gaming/wiki). Based on [Larry Gadea's](http://lg.io/) excellent work.

## Modifications in Fork

Mostly minor additions and changes to help my workflow. Check the commit log for the little things.  

**Check out [the `create-ami` folder](https://github.com/thecarlhall/ec2gaming/tree/master/create-ami) for a simpler way to create your AMI.**

1. Add scripts to describe the ec2gaming images, create a pem file, and start on-demand instance (rather than spot).
2. Add CDK constructs to create infra instead of relying on scripts like `ec2gaming-start.sh` to handle that. Makes the infra easier to clean up and manage separately from commands.
3. Tag everything with `project:ec2gaming` to track costs and resources.


# Before you begin

~~Follow the [first time configuration](https://github.com/DanielThomas/ec2gaming/wiki/First-time-configuration) steps. They help you setup the tools, and streamline creation of your personalized AMI.~~

Borrow an AMI from someone or build your own. Once you have one, you don't need to create new ones manually, but you should update and take new snapshots periodically (`ec2gaming snapshot` will destroy old snapshots and create new ones).

**Create an AMI from scratch**
Use [the `create-ami` folder](https://github.com/thecarlhall/ec2gaming/tree/master/create-ami) to create your AMI. After taking a snapshot, this stack can/should be destroyed.

**Setup Baseline Resources for Gaming**
1. Create an EC2 KeyPair and same the PEM file.
2. Use [ec2gaming.template.json](https://github.com/thecarlhall/ec2gaming/blob/master/ec2gaming.template.json) to create a CloudFormation stack with resources to be reused between gaming sessions. The `ec2gaming` scripts have checks for existing resources (security group, S3 bucket, etc). `ec2gaming start` will create these for you, but I prefer to manage them as a CloudFormation stack.

# Gaming!

1. Run `ec2gaming ondemand` (for on-demand) or `ec2gaming start` (for spot, good luck!). The instance, VPN and Steam will automatically start
2. Open Parsec and wait for server to show up.
3. Enjoy!
4. **The instance will run forever if you don't kill it thus charging you a lot.** When you're done, run `ec2gaming stop` (stops vpn and terminates instance) or `ec2gaming terminate`.

# Help

The original blog posts and the cloudygamer subreddit are great resources:

- http://lg.io/2015/07/05/revised-and-much-faster-run-your-own-highend-cloud-gaming-service-on-ec2.html
- https://www.reddit.com/r/cloudygamer/
