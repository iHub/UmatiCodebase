'''
Created on Nov 10, 2013

@author: phcostello
'''

# if __name__ == '__main__':
#     pass
from BoilerPlate import *

## get unique labels as done in sklearn.metrics super annoytng
def unique_labels(*lists_of_labels):
    """Extract an ordered array of unique labels"""
    labels = set().union(*(l.ravel() if hasattr(l, "ravel") else l for l in lists_of_labels))
    return np.asarray(sorted(labels))





# Import data
rawdata = pd.read_csv('20131107_UmatiData.csv')

from pandas.io.parsers import  ExcelFile
xls = ExcelFile('20131107_UmatiData.xls')
rawdata = xls.parse('20131107_UmatiData', index_col=None, na_values=['NA'])

#drop na actual text rows

rawdata = rawdata.dropna(subset=['Actual text'])

# Extract features
text = rawdata['Actual text']
# floats = []
# for id, it in enumerate(text.tolist()):
#     if isinstance(it, float):
#         floats.append(id)
# floats


#Make large word features
#uses sklearn CountVectoriser/bag of words
#This is fitting vocab
from sklearn.feature_extraction.text import CountVectorizer
vectoriser_training = CountVectorizer(min_df=1,stop_words='english',strip_accents='unicode')
t = time.time()
features = vectoriser_training.fit_transform(text) 
print "training text to word vector took", time.time()-t, "seconds"
features.shape
#Change from sparse matrix to dense matrix
#vect_train = features_msg_training.todense() #BIG memory usage 2GB, see how to use the sparse for training

#Create target
target = rawdata['The text /article can be seen as encouraging the audience to']
target = target.values
target.shape

#Create multilable target
target_ml = [it.replace('animals, ','animals,') for it in target] #Do this so don't split category incorrectly
target_ml = [ it.split(', ') for it in target_ml]
target_ml = [ [it.strip() for it in row] for row in target_ml ]
target_ml[:30]
[it for it in target_ml if len(it)>1]


from sklearn.preprocessing import LabelBinarizer

lb = LabelBinarizer()
lb.fit(target_ml)
lb.classes_
lb.multilabel
bin_labels = lb.transform(target_ml)
bin_labels.shape
# binLabels = [lb.transform(it) for it in target_ml]
binLabels[0]

type((1,2,3))

#Create classifier
from sklearn.svm import LinearSVC
from sklearn.multiclass import OneVsRestClassifier
X= features
y = target_ml

t = time.time()
clfinner=LinearSVC(C=1,penalty ='l1',dual=False)

clf = OneVsRestClassifier(clfinner)
clf.fit(X,y)
clf.multilabel_
print "training took", time.time()-t, "seconds"

#Check performance
training_predicted = clf.predict(X)

training_predicted

from sklearn import metrics

cm_training = metrics.confusion_matrix(y,training_predicted)
print "Confusion Matrix on training data"
print cm_training

from sklearn import cross_validation

y[(1,4)]

[ y[it] for it in [1,4] ]

Xcsr = X.tocsr()
row = Xcsr[0].todense()
skf = cross_validation.StratifiedKFold(y=target, n_folds=3)
for train_index, test_index in skf:
    print("TRAIN:", train_index, "TEST:", test_index)
    X_train, X_test = Xcsr[train_index], Xcsr[test_index]
    y_train, y_test = [y[it] for it in train_index], [y[it] for it in test_index]
    


#Cross validation not straightforward with sparse matrix
#as iterating over k-folds requires X to dense as has to slice
#on ranges. When doing the fitting this kill computer memory

clfs = []
cms = []
labels = []
for train_index, test_index in skf:
    y_train = [y[it] for it in train_index]
    y_test = [y[it] for it in test_index]
    this_clf =clf.fit(Xcsr[train_index],y_train)
    clfs.append(this_clf)
    this_predicted = this_clf.predict(Xcsr[test_index])
    print np.array(zip(y_test,this_predicted))
    
# #         print clf.fit(Xcsr[train_index],y[train_index]).score(Xcsr[test_index],y[test_index])
# #     this_label1 = unique_labels(list(y[test_index]))
# #     this_label2 = unique_labels(list(this_predicted))
#     this_label1 = np.unique(y[test_index]).tolist()
#     this_label2 = np.unique(this_predicted).tolist()
#     this_label = list(set(this_label1).union( set(this_label2)))
#     print this_label
# #     this_label = this_label.tolist()
#     print len(this_label)
#     cm_test = metrics.confusion_matrix(y_test,
#                                        this_predicted)#,this_label) 
#     print cm_test.shape
# #     labels.append(this_label)
#     cms.append(cm_test)
#     
#    


 
df = pd.DataFrame(cms[0], index= labels[0], columns=labels[0])

cms[0]

df.to_csv('output.csv')

this_predicted = clfs[1].predict(X)
cm_training = metrics.confusion_matrix(y,this_predicted)
print "Confusion Matrix on training data"
print cm_training.shape



df=pd.DataFrame(target)
df['predicted']=this_predicted
df.to_csv('output.csv')
