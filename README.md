# packer-openstack-centos-image
Build cloud ready qcow2 image with packer from kickstart file and minimal iso

packer : https://www.packer.io
this is an adaptation of packer template and a simple kikstart to generate openstack cloud images.
actually it generates a qcow2 cloud ready image, with this command:
packer build template_centos6.json
 
a glance image-create command is needed to import the qcow2 image to glance

