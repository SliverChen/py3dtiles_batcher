py3dtiles_merger
================
Forked from https://github.com/Tofull/py3dtiles_batcher



在原有的基础上添加了一些操作

实验环境配置说明：
#############

- Ubuntu 18.4.6

- Python 3.7 (3.10存在不兼容的现象)

(使用Windows的兼容性不高：如果要用建议下载Docker for windows: https://get.daocloud.io/toolbox/)



文件修改(In py3dtiles_batcher)
#############

在后续执行py3dtiles_batcher.exe时会因为路径非法导致出现错误

具体为 invalid mode: /data_in

因为作者在编写py3dtiles_batcher中的command_line.py时路径后面默认跟上一个冒号":"，因此可能会出现xx/:/data_in的情况。所以先修改command_line.py中https://github.com/SliverChen/py3dtiles_batcher/blob/2c5ca8305af3acb0816e71207aa517362ee713b4/py3dtiles_batcher/command_line.py#L87

    .. code-block:: shell
    
        commandline = 'docker run --init --rm -v {} -v {} {} py3dtiles convert --overwrite True --srs_in {} --srs_out {} --out \"/data_out/{}\" --cache_size {} \"/data_in/{}\" --rgb {}'.format(
            path,
            folder_tiles_path,
            docker_image,
            srs_in,
            srs_out,
            name_base64,
            cache_size,
            basename,
            rgb)
        


Installation (In py3dtiles)
#############


    .. code-block:: shell

        $ git clone https://github.com/Tofull/py3dtiles
        $ cd py3dtiles


需要注意：使用docker build的时候需要存在一个Dockerfile文件

相当于呈现一个从0到1的安装流程

Dockerfile文件格式可以参考下面的内容：

参考：https://github.com/vitlok-cyberhawk/py3dtiles-dockerised

    .. code-block:: shell
    
         FROM ubuntu:bionic

         RUN apt-get update && apt-get install -y sl

         RUN apt-get install -y git python3 python3-pip virtualenv libopenblas-base liblas-c3

         RUN git clone https://github.com/Oslandia/py3dtiles

         WORKDIR /py3dtiles

         RUN virtualenv -p /usr/bin/python3 venv
         RUN . venv/bin/activate
         RUN /py3dtiles/venv/bin/pip install -e .
         RUN /py3dtiles/venv/bin/python setup.py install
         RUN ln -s /py3dtiles/venv/bin/py3dtiles /usr/local/bin

         WORKDIR /3ddata

         ENTRYPOINT [ "py3dtiles" ]
    
    
同时，需要在requirements.txt限制numpy版本在[1.7,1.21)之间。

原因在于后续安装的numba库对numpy存在版本依赖

requirements.txt文件格式可以参考下面的内容：


      .. code-block:: shell
      
            numpy==1.20.3
            pyproj 


执行镜像构建(注意后面的点)：


    .. code-block:: shell
    
        $ docker build -t py3dtiles .


Installation (In py3dtiles_batcher)
#############

克隆py3dtiles_batcher，并且运行docker镜像来进行转换操作：

   .. code-block:: shell
   
         $ git clone https://github.com/Tofull/py3dtiles_batcher.git
         $ cd py3dtiles_batcher
         $ docker run -it --rm -v "/path/libDIr":"/3ddata" py3dtiles convert data.las


使用的注意事项:
#################

由于py3dtiles中涉及到venv的使用，无法在共享文件夹中直接运行docker

如果想要转换windows下传来的文件，需要事先将文件复制一份到linux本地文件夹下再进行转换


可行性分析：
################

由于docker构建比较麻烦，对于一台没有docker的主机而言移植性差。

最好的办法是在linux中将这个py3dtiles打包成独立的可执行程序，并且传到


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
