py3dtiles_merger
================
Forked from https://github.com/Tofull/py3dtiles_batcher



在原有的基础上添加了一些操作

实验环境配置说明：
#############

- Windows10 家庭版（如果支持Hyper-V，可以直接下载Docker for windows）
（Docker for windows下载链接：http://get.daocloud.io/#install-docker-for-mac-windows）

- Docker Toolbox 19.03.1（下载链接：https://get.daocloud.io/toolbox/）
配置教程：https://blog.csdn.net/weixin_44038167/article/details/109485148


Installation
#############


    .. code-block:: shell

        $ git clone https://github.com/Tofull/py3dtiles
        $ cd py3dtiles


需要注意：使用docker build的时候需要存在一个Dockerfile文件

Dockerfile文件格式可以参考下面的内容（仅供参考）：

    .. code-block:: shell
    
         FROM python:3.7
         WORKDIR /usr/src/app
         COPY requirements.txt ./
    
         RUN sed -i "s/archive.ubuntu./mirrors.aliyun./g" /etc/apt/sources.list \
            && sed -i "s/deb.debian.org/mirrors.aliyun.com/g" /etc/apt/sources.list \
            && sed -i "s/security.debian.org/mirrors.aliyun.com\/debian-security/g" /etc/apt/sources.list \
            && sed -i "s/httpredir.debian.org/mirrors.aliyun.com\/debian-security/g" /etc/apt/sources.list \
            && pip install -U pip \
            && pip config set global.index-url http://mirrors.aliyun.com/pypi/simple \
            && pip config set install.trusted-host mirrors.aliyun.com
    
         RUN pip install --no-cache-dir -r requirements.txt
    
         COPY . .
         ENTRYPOINT ["python"]
         CMD ["./setup.py","install"]
    
    
同时，如果你的numpy版本是>1.21的话需要移除并在requirements.txt限制numpy版本在[1.7,1.21)之间。

原因在于后续安装的numba库对numpy存在版本依赖

requirements.txt文件格式可以参考下面的内容：


      .. code-block:: shell
      
            numpy==1.20.3
            pyproj 


执行镜像构建(注意后面的点)：


    .. code-block:: shell
    
        $ docker build -t py3dtiles .


然后克隆py3dtiles_batcher，并且运行docker镜像：

   .. code-block:: shell
   
         $ git clone https://github.com/Tofull/py3dtiles_batcher.git
         $ cd py3dtiles_batcher
         $ docker run -it -p 5000:5000 py3dtiles setup.py install


在运行前的建议:

将本地pip源改为国内镜像

修改方法：

定位到~/.pip/pip.conf，没有就创建，然后写入以下语句

    .. code-block:: shell
           
           [global]
           timeout = 6000
           index-url = http://mirrors.aliyun.com/pypi/simple/
           trusted-host = mirrors.aliyun.com


最终生成的exe文件在Python根目录下的scripts目录中


Usage
###########

    .. code-block:: shell

        usage: py3dtiles_batcher [-h] [--dryrun] [--incremental] [--srs_in SRS_IN]
                         [--srs_out SRS_OUT] [--cache_size CACHE_SIZE]
                         [--docker_image DOCKER_IMAGE] [--verbose] [--norgb]
                         output_folder [input_folder [input_folder ...]]

        Convert .las file to 3dtiles in batch.

        positional arguments:
        output_folder         Directory to save tiles.
        input_folder          Directory to watch. (default: .)

        optional arguments:
            -h, --help            show this help message and exit
            --dryrun              Active dryrun mode. No tile will be generated in this
                                    mode. (default: False)
            --incremental         Active incremental mode. Skip tile if
                                    <output_folder>/<tile>/tileset.json exists. (default:
                                    False)
            --srs_in SRS_IN       Srs in. (default: 2959)
            --srs_out SRS_OUT     Srs out. (default: 4978)
            --cache_size CACHE_SIZE
                                    Cache size in MB. (default: 3135)
            --docker_image DOCKER_IMAGE
                                    py3dtiles docker image to use. (default: py3dtiles)
            --verbose, -v         Verbosity (-v simple info, -vv more info, -vvv spawn
                                    info) (default: 0)
            --norgb               Do not export rgb attributes (default: True)

        Working example (remove --dryrun when you want to generate tiles) :
        py3dtiles_batcher.exe "D:\data_py3dtiles\output" "D:\data_py3dtiles\raw" --dryrun -v


Examples
##########


If you want to convert all `.las` from "D:\data_py3dtiles\raw" directory and save result into "D:\data_py3dtiles\output":

    .. code-block:: shell

        # On windows
        py3dtiles_batcher.exe -v "D:\data_py3dtiles\output" "D:\data_py3dtiles\raw"


You can select specific files or folder you want to convert:

    .. code-block:: shell

        # On windows
        py3dtiles_batcher.exe -v "D:\data_py3dtiles\output" "D:\data_py3dtiles\raw" "D:\folder1\file1.las" "D:\folder2"


Notes :
#############

- Remember to specify the `srs_in` option if its differs from EPSG:2959

- output path will be written in base64 encodage, to respect URL’s standard (which will be useful for 3d webviewer [Read What's next section]). Don't be surprised.


What's next ?
##############

* Visualize 3dtiles individually

    Once yours `.las` files have been converted into 3dtiles, you can expose them individually over the Internet with any http server, like :

        .. code-block:: shell

            # using https://www.npmjs.com/package/http-server
            npm install http-server -g
            http-server D:\data_py3dtiles\output --cors -p 8080

    Then, each tileset in subfolder is available over the Internet, and you can visualize it one by one using a 3d viewer, for example Cesium sandcastle : 

    1. Go to https://cesiumjs.org/Cesium/Build/Apps/Sandcastle/index.html
    2. Insert the following code on Javascript Code section. Replace <base64_name> by the name of the directory of the tileset.json you want to visualize.

        .. code-block:: javascript
        
            var viewer = new Cesium.Viewer('cesiumContainer');
            var tileset = viewer.scene.primitives.add(new Cesium.Cesium3DTileset({
                url : 'http://127.0.0.1:8080/<base64_name>/tileset.json'
            }));

    3. Click Run (or F8) and enjoy.

        .. image:: doc/assets/example_3dtiles_on_cesium.png
            :width: 200px
            :align: center
            :height: 100px
            :alt: Example on cesium

* Visualize merged 3dtiles

    If you want to visualize all your 3dtiles at the same time, some steps are required to merge them into one big tileset.json.
    Hopefully, I created the merger tool. Please refer to it by clicking on the following link : https://github.com/Tofull/py3dtiles_merger

    After some discussion with Oslandia' developers team, they have released a new version of py3dtiles with a "merge" command which is intended to do a better stuff than py3dtiles_merger. The previous command "py3dtiles" (renamed as "py3dtiles convert") - used to generate the individual 3dtiles - needed some changes (a well-done hierarchical 3d points structure from children, reconsidering a true computation of the geometricError attribute).

Contribution
#############

Contributions are welcome. Feel free to open an issue for a question, a remark, a typo, a bugfix or a wanted feature.



Licence
##########

Copyright © 2018 Loïc Messal (@Tofull) and contributors

Distributed under the MIT Licence.
