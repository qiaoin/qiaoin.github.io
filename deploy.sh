# 不要直接进行执行，主要是用来作为命令备忘
# 将 public 目录作为一个单独的仓库
cd public

# 仓库进行独立的 user 和 email 配置
git config user.name qiaoin
git config user.email qiao.liubing@gmail.com
git config --local --list
# 如果 git commit 的 author 错误，进行修改
git commit --amend --author="qiaoin <qiao.liubing@gmail.com>"

git init
git add -A
git commit -m 'deploy'

git remote add origin https://github.com/qiaoin/qiaoin.github.io.git
git push origin master -f

# github page 会有 10 分钟左右的延迟
git commit --allow-empty -m "Trigger rebuild"
git push --set-upstream origin master
