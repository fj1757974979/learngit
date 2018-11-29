cd web && sh gen_gonggao.sh
cd ..
rsync -av -e 'ssh -p 22' web/web_ios/* server@106.75.132.200:/home/server/web/gjxx_web_ios/static/
rsync -av -e 'ssh -p 22' web/web_android/* server@106.75.132.200:/home/server/web/gjxx_web/static/
