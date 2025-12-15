PYTHON ?= python3

.PHONY: install prep train serve autotrain test

install:
	$(PYTHON) -m pip install -r requirements.txt

prep:
	$(PYTHON) -m src.data_prep

train:
	$(PYTHON) -m src.train_model

serve:
	$(PYTHON) -m uvicorn src.api:app --host 0.0.0.0 --port 8000 --reload

autotrain:
	$(PYTHON) -m src.auto_train

test:
	pytest -q

