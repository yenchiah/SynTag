#################################################################
# 		ReadMe: vod service		 	 	#
#								#
#################################################################

The vod service is an Adobe-built service that lets you stream 
media to users without writing any code.
 
Adobe Flash Media Streaming Server only runs Adobe-built services, 
also called "signed" applications.

Adobe Flash Media Interactive Server and Adobe Flash Media 
Development Server support unsigned (user-created) applications. If 
you're using one of these server versions, you can modify the vod 
service source code to create your own applications.


=======================================================================
Deploying custom vod service
(Flash Media Interactive Server or Flash Media Development Server only)
=======================================================================

To deploy an unsigned version of the vod service you can either replace 
the existing service, or create a new service.

1. [New Service] Create a new folder in the {FMS-Install-Dir}/applications 
   folder. 

2. [Existing Service] To replace the default Adobe-signed vod 
   service, first back up the following files from the folder 
   {FMS-Install-Dir}/applications/vod: 
   
   * main.far
   * Application.xml
   * allowedHTMLDomains.txt
   * allowedSWFDomains.txt 

3. Copy all files from {FMS-Install-Dir}/samples/applications/vod to 
   the folder you created in step 1 or to the existing folder, 
   {FMS-Install-Dir}/applications/vod.

4. To configure the vod service, open the file 
   {FMS-Install-Dir}/applications/{Your-New-Folder}/Application.xml.
   
   Locate the following elements:
   <Streams>/;${VOD_COMMON_DIR}</Streams>
   <Streams>/;${VOD_DIR}</Streams>

   These variables hold the location of the folder that the vod application 
   searches for media files when a stream play request is received. Their 
   values are set in the fms.ini file. For RTMP delivery, Flash Media Server 
   checks folders for media files in the order of the <Streams> elements.
   
   ${VOD_COMMON_DIR} This variable stores the location of media files 
   accessible by both RTMP and HTTP (if installed). 
   
   ${VOD_DIR} This variable stores the location of media files accessible by 
   RTMP only through the /applications/vod service only.
   
   Alternatively, the path for media files can be changed in following ways:

	A. Edit the <Streams> element to map to a directory, for example:
	   <Streams>/;C\my_stream_and_pd_dir</Streams>
	   <Streams>/;C\my_stream_only_dir</Streams>
		Note : If you are using the default installation of the 
		       FMS HTTP service, and if you modify VOD_COMMON_DIR, 
		       change the document root, set in   
		       {FMS-Install-Dir}/Apache2.2/conf/httpd.conf. 

	B. Create a new variable in {FMS-Install-Dir}/conf/fms.ini file, 
	   for example: MY_VOD_DIR= C\my_stream_dir. 
	   Next, edit the <Streams> element in the Application.xml file:
	      <Streams>/;${MY_VOD_COMMON_DIR}<Streams>
	      <Streams>/;${MY_VOD_DIR}</Streams>

-------------------------------------------------------------------------

For information about using and configuring the vod service, see the 
Developer Guide (flashmediaserver_3.5_dev_guide.pdf) in the 
{FMS-Install-Dir}/documentation folder. 

For information about troubleshooting the vod service, see
the Installation Guide (flashmediaserver_3.5_install.pdf) in the same 
location.
