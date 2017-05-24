/*
 * 公共样式
 * huacao
 */
//沉淀工作
var Wiki = (function(){
    return {
        // 显示弹层, 配置title、 content、callback
        showEditerDialog: function(conf){
            var dialogWin = dialog({
                width: 1000,
                title: conf.title,
                content: conf.content,
                onshow: function() {
                    $(this.node).find('.close_dialog').on('click', function(){
                        dialogWin.close().remove();
                        return false;
                    });

                    conf.callback && conf.callback(dialogWin);
                },
            });
            
            dialogWin.showModal();
        },
        // 获取文章内容
        getArticle: function(id){
            var article = $(id);
            return {
                title: article.find('> .title').text(),
                content: article.find('> .content').html()
            }
        },
        // 添加文章编辑器
        addArticle: function(){
            var editorId = Math.random().toString(36).substr(2); // 生成随机ID
            var _html = $($('#wit_add_editor_tpl').html());
            _html.find('.wit-editor').attr('id', editorId);
            _html.find('.select2_box').select2();

            Wiki.showEditerDialog({
                title: '添加文档',
                content: _html,
                callback: function(){
                    var editor = UM.getEditor(editorId);
                }
            });       
        },
        // 编辑文章编辑器
        editArticle: function(aid){
            var article = Wiki.getArticle(aid); 
            var editorId = Math.random().toString(36).substr(2);

            var _html = $($('#wit_editor_tpl').html());
            _html.find('.title').val(article.title);
            _html.find('.wit-editor').attr('id', editorId).html(article.content);
            _html.find('.select2_box').select2();

            Wiki.showEditerDialog({
                title: '编辑文档',
                content: _html,
                callback: function(){
                    var editor = UM.getEditor(editorId);
                }
            }); 
        },
        // 事件绑定
        bindCatalogueLister: function(){
            // 跳转到相应文档
            var originPath = location.href;
            $('#tree_view').on('click', '.tree-name', function(){
                var href = $(this).closest('.jstree-anchor').attr('href');
                var position = $(href).offset();
                var y = position.top - 60 + 'px';
                $('body').animate({scrollTop: y},800);
                return false;
            });

            // 删除文章
            $('#tree_view').on('click', '.remove-btn', function(){
                var d = dialog({
                    width: 260,
                    title: '提示',
                    content: '<div class="king-notice-box king-notice-question">'+
                                    '<p class="king-notice-text">'+
                                       ' 确定要删除此目录？'+
                                    '</p>'+
                                '</div>',
                    okValue: '确定',
                    ok: function() {
                        // this.title('提交中…');
                        // return false;
                    },
                    cancelValue: '取消',
                    cancel: function() {}
                });
                d.showModal();

                return false;
            });

            // 目录入口编辑文章
            $('#tree_view').on('click', '.edit-btn', function(){
                var aid = $(this).closest('.jstree-anchor').attr('href');
                Wiki.editArticle(aid);
                return false;
            });
            // 文章入口编辑文章
            $('.wit-wiki-box').on('click', '.edit-btn', function(){
                var aid = '#' + $(this).closest('.article').attr('id')
                Wiki.editArticle(aid);
                return false;
            });

            // 添加文章
            $('#tree_view').on('click', '.add-btn', function(){
                Wiki.addArticle();
                return false;
            });

            // 编辑状态
            $('#edit_tree_btn').on('click', function(){
                $('.wit-tree-view').toggleClass('edit-status');
            });
        },
        initHistoryTimer: function(){
            $('#daterangepicker').daterangepicker({
                "showDropdowns": true,//显示年，月下拉选择框
                "showWeekNumbers": true,//显示第几周
                "timePicker": true,//时间选择
                "timePicker24Hour": true,//24小时制
                "timePickerIncrement": 1,//时间间隔
                "timePickerSeconds": true,
                "dateLimit": { //可选择的日期范围
                    "days": 30
                },
                "ranges": {
                    "前7天" : [moment().subtract(6, 'days'), moment()],
                    "前30天" : [moment().subtract(29, 'days'), moment()],
                    "本月" : [moment().startOf('month'), moment().endOf('month')],
                    "上个月" : [moment().subtract(1,'month').startOf('month'), moment().subtract(1,'month').endOf('month')],
                },
                "locale": {
                    "format": "YYYY-MM-DD",// 日期格式
                    "separator": " 至 ",
                    "applyLabel": "确定",
                    "cancelLabel": "取消",
                    "fromLabel": "从",
                    "toLabel": "到",
                    "weekLabel": '周',
                    "customRangeLabel": "自定义",
                    "daysOfWeek": [
                        "日",
                        "一",
                        "二",
                        "三",
                        "四",
                        "五",
                        "六"
                    ],
                    "monthNames": [
                        "一月",
                        "二月",
                        "三月",
                        "四月",
                        "五月",
                        "六月",
                        "七月",
                        "八月",
                        "九月",
                        "十月",
                        "十一月",
                        "十二月"
                    ],
                    "firstDay": 1// 周开始时间
                },
                "opens": "right",//left/center/right
                "buttonClasses": "btn btn-sm",//按钮通用样式
                "applyClass": "btn-success",//确定按钮样式
                "cancelClass": "btn-default"//取消按钮样式
            });
        },
        // 初始化历史记录入口
        initHistory: function(){
            Wiki.initHistoryTimer();
        },
        // 初始化工作文档目录入口
        initWikiCatalogue: function(){
            $('#tree_view').jstree({
                "core" : {
                    "animation" : 0,
                    "check_callback" : true,
                  },
                "types" : {
                    "#" : {
                      "max_children" : 1,
                      "max_depth" : 4,
                      "valid_children" : ["catalogue"]
                    },
                    "catalogue" : {
                      "valid_children" : ["article"]
                    },
                    "article" : {
                      "valid_children" : []
                    }
                },
                "plugins" : [
                    "dnd", "types"
                ]
            }).on('ready.jstree', function(){
                Wiki.bindCatalogueLister();
            });
        }
    }
})();

// 跟进事项

var Follow = (function(){
    return {
        bindListener: function(){
            $('#add_follow_btn').on('click', function(){
                var _html = $($('#wit_add_follow_tpl').html());
                var editorId = Math.random().toString(36).substr(2); // 生成随机ID
                _html.find('.wit-editor').attr('id', editorId);

                Wiki.showEditerDialog({
                    title: '新建事项',
                    content: _html,
                    callback: function(){
                        var editor = UM.getEditor(editorId);
                    }
                });  

                return false;
            });
        },
        init: function(){
            Follow.bindListener();
        }
    }
})();
