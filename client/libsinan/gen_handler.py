import libsinan.handler
import re

class GenHandler(libsinan.handler.Handler):
    DEFAULT_REPO = "http://repo.erlware.org/writable"

    def handles(self, task):
        return task == "gen"

    def valid_repo(self, repo):
        return not repo.strip() == ""

    def get_repositories(self):
        print "Please specify the locations of the repositories. "
        value = self.ask_user('repository', self.DEFAULT_REPO)
        values = [value]

        more = self.ask_user('would you like to enter another y/n', 'n').upper()
        if more == 'Y' or more == 'YES':
            while 1:
                value = self.ask_user('repository')
                values.append(value)
                more = self.ask_user('would you like to enter another y/n',
                                     'n').upper()
                if more == 'N' or more == 'NO':
                    break
        return values


    def gather_user_info(self):
        print "Please specify your name"
        name = self.ask_user("your name")
        print "Please specify your email address"
        address = self.ask_user('your email')
        print "Please specify the copyright holder"
        copyholder = self.ask_user('copyright holder', name)

        if not copyholder:
            copyholder = name

        return {"username" : name,
                "email_address" : address,
                "copyright_holder" : copyholder}


    def get_application_names(self):
        print ("Please specify the names of the OTP apps" +
        " that belong to this project. ")
        value = self.ask_user('app')
        values = value.split()

        more = self.ask_user('would you like to enter more y/n', 'n').upper()
        if more == 'Y' or more == 'YES':
            while 1:
                value = self.ask_user('app')
                values = values + value.split()
                more = self.ask_user('would you like to enter another y/n',
                                     'n').upper()
                if more == 'N' or more == 'NO':
                    break
        return values



    def get_new_project_info(self):
        print "Please specify name of your project"
        name = self.ask_user('project name')
        print "Please specify the version of your project \n"
        version = self.ask_user('project version', '0.1.0.0')

        return {"project_version" : version,
                "project_name" : name}


    def handle(self, largs):
        """ Query the user for information about the user and
        the project he wishes to create before passing that
        information to the user """
        try:
            largs['opts']['tasks']['gen']
        except KeyError:
            if not largs['opts'].has_key('tasks'):
                largs['opts']['tasks'] = {}

            shell_info =  {"user_info" : self.gather_user_info(),
                           "repositories" : self.get_repositories(),
                           "project_info" :
                           self.get_new_project_info(),
                           "apps" : self.get_application_names()}
            largs['opts']['tasks']['gen'] = shell_info
        self.do_request(largs)




libsinan.add_task_handler(GenHandler())
