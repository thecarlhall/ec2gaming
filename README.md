# ec2gaming - EC2 Gaming on macOS

Provides command line tools that makes gaming on EC2 simple and reliable. Includes steps to create an AMI that requires no intervention on startup, allows Steam remote installs and minimizes the amount of time game installs take.

Full documentation is available on the [wiki](https://github.com/DanielThomas/ec2gaming/wiki). Based on [Larry Gadea's](http://lg.io/) excellent work.

## Modifications in Fork

Mostly minor additions and changes to help my workflow. Check the commit log for the little things.  

**Check out [this other repo](https://github.com/thecarlhall/cloud-gaming-on-ec2-instances) for a simpler way to create your AMI.**

1. Add scripts to describe the ec2gaming images, create a pem file, and start on-demand instance (rather than spot).
2. Add CDK constructs to create infra instead of relying on scripts like `ec2gaming-start.sh` to handle that. Makes the infra easier to clean up and manage separately from commands.
3. Tag everything with `project:ec2gaming` to track costs and resources.


# Before you begin

~~Follow the [first time configuration](https://github.com/DanielThomas/ec2gaming/wiki/First-time-configuration) steps. They help you setup the tools, and streamline creation of your personalized AMI.~~
Use [my other repo](https://github.com/thecarlhall/cloud-gaming-on-ec2-instances) to create your AMI. After taking a snapshot, this stack can be destroyed.

# Gaming!

- Run `ec2gaming ondemand` (for on-demand) or `ec2gaming start` (for spot). The instance, VPN and Steam will automatically start
- Open Parsec and wait for server to show up.
- Enjoy!
- When you're done, run `ec2gaming stop` (stops vpn and terminates instance) or `ec2gaming terminate`.

# Help

The original blog posts and the cloudygamer subreddit are great resources:

- http://lg.io/2015/07/05/revised-and-much-faster-run-your-own-highend-cloud-gaming-service-on-ec2.html
- https://www.reddit.com/r/cloudygamer/
