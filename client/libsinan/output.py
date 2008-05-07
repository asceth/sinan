import libsinan.jsax

class SimpleTaskHandler(object):
    def __init__(self):
        self.event_type = None
        self.type = None
        self.desc = None
        self.task = None

    def set_event_type(self, value):
        self.event_type = value

    def set_type(self, value):
        self.type = value

    def set_desc(self, value):
        self.desc = value

    def set_task(self, value):
        self.task = value

    def object_begin(self):
        return True

    def key(self, value):
        if value == "event_type":
            self.next = self.set_event_type
        elif value == "type":
            self.next = self.set_type
        elif value == "desc":
            self.next = self.set_desc
        elif value == "task":
            self.next = self.set_task

        return True

    def value_begin(self):
        return True

    def string(self, value):
        self.next(value)
        return True

    def number(self, value):
        self.next(value)
        return True

    def true(self):
        self.next(Value)
        return True

    def false(self):
        self.next(Value)
        return True

    def null(self):
        self.next(Value)
        return True

    def array_begin(self):
        self.array = []
        return True

    def array_end(self):
        self.next(self.array)
        self.array = None
        return True

    def object_end(self):
        """ We only get one object per right now so
        lets print it out when we get it """

        if self.type == "task_event" and self.desc and self.event_type == "io":
            print self.desc,
        elif self.type == "task_event" and self.desc:
            addition = ""
            if self.event_type == "fault":
                addition = " fault!!"

            print "[" + self.task + addition + "]", self.desc
        elif self.type == "task_event":
            print "[" + self.task + "]", self.event_type
        elif self.type == "run_event" and self.desc:
            print "1", self.desc
        elif self.type == "run_event" and self.event_type == "start":
            print "starting run"
        elif self.type == "run_event" and self.event_type == "stop":
            print "run complete"
        elif self.type == "run_event" and self.event_type == "fault":
            print "run complete with faults"

        self.event_type = None
        self.type = None
        self.desc = None
        self.task = None
        self.next = None
        return True

    def value_end(self):
        return True

def handle(task, conn):
    """ Handles output from the server. For the most part this just
    parses the default types of event layout and prints it to standard out
    in special cases it may do something else """
    libsinan.jsax.parse(conn, SimpleTaskHandler())

