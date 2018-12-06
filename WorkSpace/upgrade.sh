#!/bin/bash

# 将基础版本从 2.1.0 升级到 2.1.2 
source /etc/profile.d/NETPAS_VAR.sh
source ${NETPAS_ETC}/S3_BASE.func

# 定义升级日志文件
UpgradeLog=/var/log/xelerate-upgrade.log
exec > >(tee -a "${UpgradeLog}") 2>&1

# 定义升级仓库升级相关变量
export BucketName=lets-nodes
UpdateVersion={{2.1.2}}
UpgradePath=/opt/UPGRADE-${UpdateVersion}
RedisVar='redis://:lets.websocket@127.0.0.1:6379/3'

# 判断是否有需要升级的子模块
UpgradeRepo=`pscf yaml --config repo-info --get upgrade_list`
case ${UpgradeRepo} in
none|NONE|None|''|' ')
    echo "没有需要升级的子模块"
    exit 1
    ;;
*)
    echo "即将对各个模块进行升级 ... ..."
    ;;
esac

# 获取升级仓库个数
TempNum=`awk '/upgrade_list/,/^[a-zA-Z0-9]*$/ {print}' repo-info | grep -v '^$' |wc -l`
RepoNum=`expr ${TempNum} - 1`

# 对各个仓库安装状态做统计
declare -i COUNT=0

# 显示当前节点 image 版本信息
VERSION=`pscf yaml -c ${NETPAS_ETC}/images.yaml --get image.version`
echo "This Server DIST-VERSION is : [$VERSION]"

# 升级各个子模块
function UPGRADE_SUBREPO(){
    test -d ${UpgradePath}
    if [ $? -eq 0 ]
    then
        echo "升级文件已存在，请人工检查是否升级失败。"
        exit 1
    else
        mkdir -pv ${UpgradePath}
        for UpgRepo in `pscf yaml --config repo-info --getkeys upgrade_list`
        do
            UP_REPO_TAG=`pscf yaml --config repo-info --get upgrade_list.\"${UpgRepo}\"`
            cd ${UpgradePath}
            rm -rf ${UpgRepo}; mkdir -pv ${UpgRepo}
            aws s3 cp s3://${BucketName}/${UpgRepo}/${UP_REPO_TAG}/${UpgRepo}.tar.gz ./${UpgRepo}
            cd ./${UpgRepo} && tar xf ${UpgRepo}.tar.gz && ./upgrade.sh
            [ $? -eq 0 ] && let COUNT+=1 || echo -e "\033[31m${SUB_REPO} Installation Failure\033[0m"
        done
    fi
}

# 根据各仓库执行结果进行镜像状态修改
if [ ${COUNT} -ge ${RepoNum} ]
then
    sed -i 's/status.*/status: active/g' ${NETPAS_ETC}/images.yaml
    sed -i '/store/d' ~/.gitconfig ; rm -rf ~/.git-credentials
else
    sed -i 's/status.*/status: failure/g' ${NETPAS_ETC}/images.yaml
    sed -i '/store/d' ~/.gitconfig ; rm -rf ~/.git-credentials
fi

# 修改节点版本信息
pscf yaml --config ${NETPAS_ETC}/images.yaml --set image.version=${UpdateVersion}
CUR_VERSION=`pscf yaml --config ${NETPAS_ETC}/images.yaml --get image.version`
echo "This Server Current DIST-VERSION is : [$CUR_VERSION]"

echo -e "Finish Upgrade ."
