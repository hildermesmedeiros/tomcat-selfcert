# tomcat-selfcert
Repo to understand how to publish tomcat apache with self cert.

### `tag`: apache2-tomcat:latest

#### Step 1 download tomcat to your project folder
> apache-tomcat-10.1.19.tar.gz

#### Step 2
> docker-compose build

#### Step 3
> docker-compose up


#### Step 4 Add the site hostname to your hosts
![image](https://github.com/hildermesmedeiros/tomcat-selfcert/assets/20046591/4aebc8c6-32ee-426e-88bf-6c59a41a08e1)

#### Step 5 check if its working
![image](https://github.com/hildermesmedeiros/tomcat-selfcert/assets/20046591/2a61a218-4cd1-407a-8f99-cb36e06a1ebd)

#### Step 6 export apache cert
![image](https://github.com/hildermesmedeiros/tomcat-selfcert/assets/20046591/4b28cdc6-6423-434f-b173-c336ffcda2b7)
![image](https://github.com/hildermesmedeiros/tomcat-selfcert/assets/20046591/13fedd45-d207-433c-9022-b32466eab3c4)

#### Step 7 Install the cert in Trusted Root Certification Authorities

#### Step 8 close your navigator and try to open your site. You should see in navigator the site is "valid" in your local dev env
![image](https://github.com/hildermesmedeiros/tomcat-selfcert/assets/20046591/89f1cb76-115c-490a-8b1e-791f3375bc02)



##### Notes
When creating cert for local development don't forget to set dns in open ssl and keystore, see my start.sh
